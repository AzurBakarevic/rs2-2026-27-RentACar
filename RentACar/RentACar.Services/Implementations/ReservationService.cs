using FluentValidation;
using Mapster;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using RentACar.Model.Constants;
using RentACar.Model.Enums;
using RentACar.Model.Requests;
using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;
using RentACar.Services.Database;
using RentACar.Services.Helpers;
using RentACar.Services.Interfaces;
using RentACar.Services.ReservationStateMachine;

namespace RentACar.Services.Implementations;

public class ReservationService : BaseReadService<Reservation, ReservationResponse, ReservationSearchObject>, IReservationService
{
    private readonly BaseReservationState _reservationState;
    private readonly ReservationCalculator _calculator;
    private readonly IAuthenticatedUserAccessor _authenticatedUser;
    private readonly IValidator<ReservationInsertRequest> _insertValidator;
    private readonly IValidator<ReservationRejectRequest> _rejectValidator;
    private readonly IValidator<ReservationCancelRequest> _cancelValidator;

    public ReservationService(
        IMapper mapper,
        RentACarDbContext dbContext,
        BaseReservationState reservationState,
        ReservationCalculator calculator,
        IAuthenticatedUserAccessor authenticatedUser,
        IValidator<ReservationInsertRequest> insertValidator,
        IValidator<ReservationRejectRequest> rejectValidator,
        IValidator<ReservationCancelRequest> cancelValidator) : base(mapper, dbContext)
    {
        _reservationState = reservationState;
        _calculator = calculator;
        _authenticatedUser = authenticatedUser;
        _insertValidator = insertValidator;
        _rejectValidator = rejectValidator;
        _cancelValidator = cancelValidator;
    }

    // ---------- Čitanje ----------

    // Administrator vidi sve rezervacije, a korisnik samo svoje; tuđa rezervacija za njega ne postoji (404).
    protected override IQueryable<Reservation> GetQuery() => RestrictToCurrentUser(base.GetQuery());

    protected override IQueryable<Reservation> ApplyFilters(IQueryable<Reservation> query, ReservationSearchObject search)
    {
        if (!string.IsNullOrWhiteSpace(search.Text))
        {
            var text = search.Text.Trim();
            query = query.Where(x => (x.User.FirstName + " " + x.User.LastName).Contains(text)
                                     || x.User.Username.Contains(text)
                                     || (x.Vehicle.VehicleModel.Brand.Name + " " + x.Vehicle.VehicleModel.Name).Contains(text)
                                     || x.Vehicle.RegistrationNumber.Contains(text));
        }

        if (search.UserId.HasValue)
        {
            query = query.Where(x => x.UserId == search.UserId.Value);
        }

        if (search.VehicleId.HasValue)
        {
            query = query.Where(x => x.VehicleId == search.VehicleId.Value);
        }

        if (search.Status.HasValue)
        {
            query = query.Where(x => x.Status == search.Status.Value);
        }

        if (search.IsActive.HasValue)
        {
            query = search.IsActive.Value
                ? query.Where(x => ReservationStatuses.Active.Contains(x.Status))
                : query.Where(x => !ReservationStatuses.Active.Contains(x.Status));
        }

        // Najam koji bar dijelom pada u traženi period: završava poslije njegovog početka i počinje prije njegovog kraja.
        if (search.From.HasValue)
        {
            var from = AgencyTime.AsUtc(search.From.Value);
            query = query.Where(x => x.ReturnAt > from);
        }

        if (search.To.HasValue)
        {
            var to = AgencyTime.AsUtc(search.To.Value);
            query = query.Where(x => x.PickupAt < to);
        }

        return query;
    }

    // Kao na skicama: prvo aktivne od najbližeg preuzimanja, zatim prošle od najnovije.
    protected override IQueryable<Reservation> ApplyOrdering(IQueryable<Reservation> query)
        => query.OrderBy(x => ReservationStatuses.Active.Contains(x.Status) ? 0 : 1)
            .ThenBy(x => ReservationStatuses.Active.Contains(x.Status) ? x.PickupAt : (DateTime?)null)
            .ThenByDescending(x => x.PickupAt)
            .ThenByDescending(x => x.Id);

    public override async Task<PageResult<ReservationResponse>> GetAllAsync(ReservationSearchObject? search = null)
    {
        var result = await base.GetAllAsync(search);

        foreach (var item in result.Items)
        {
            item.PaymentDeadline = PaymentRules.GetPaymentDeadline(item.CreatedAt);
            item.AllowedActions = GetAllowedActions(item);
        }

        return result;
    }

    // Detalji: uz osnovne podatke još oprema, uplata i historija statusa, svaka jednim upitom (bez N+1, upute 8.2).
    public override async Task<ReservationResponse> GetByIdAsync(int id)
    {
        var reservation = await base.GetByIdAsync(id);

        reservation.Equipment = await _dbContext.ReservationEquipment
            .AsNoTracking()
            .Where(x => x.ReservationId == id)
            .OrderBy(x => x.Equipment.Name)
            .ProjectToType<ReservationEquipmentResponse>(_mapper.Config)
            .ToListAsync();

        // Poništena plaćanja (npr. istekao rok) se ne prikazuju; aktivna uplata je najviše jedna (jedinstveni indeks).
        reservation.Payment = await _dbContext.Payments
            .AsNoTracking()
            .Where(x => x.ReservationId == id && x.Status != PaymentStatus.Cancelled)
            .ProjectToType<ReservationPaymentResponse>(_mapper.Config)
            .FirstOrDefaultAsync();

        reservation.StatusHistory = await _dbContext.ReservationStatusHistory
            .AsNoTracking()
            .Where(x => x.ReservationId == id)
            .OrderBy(x => x.ChangedAt)
            .ThenBy(x => x.Id)
            .ProjectToType<ReservationStatusHistoryResponse>(_mapper.Config)
            .ToListAsync();

        reservation.PaymentDeadline = PaymentRules.GetPaymentDeadline(reservation.CreatedAt);
        reservation.AllowedActions = GetAllowedActions(reservation);

        return reservation;
    }

    // ---------- Kreiranje ----------

    public async Task<ReservationCalculationResponse> CalculateAsync(ReservationInsertRequest request)
    {
        await _insertValidator.ValidateAndThrowAsync(request);

        var userId = _authenticatedUser.GetUserId() ?? throw new UnauthorizedAccessException();

        return await _calculator.CalculateAsync(userId, request);
    }

    // Provjera dostupnosti, obračun i upis rezervacije, opreme, historije i notifikacije idu u jednoj transakciji.
    public async Task<ReservationResponse> InsertAsync(ReservationInsertRequest request)
    {
        await _insertValidator.ValidateAndThrowAsync(request);

        await using var transaction = await _dbContext.Database.BeginTransactionAsync();

        var state = _reservationState.GetReservationState(null);
        var reservation = await state.InsertAsync(request);

        await _dbContext.SaveChangesAsync();
        await transaction.CommitAsync();

        return await GetByIdAsync(reservation.Id);
    }

    // ---------- Promjena statusa ----------

    public Task<ReservationResponse> ConfirmAsync(int id)
        => ChangeStatusAsync(id, (state, reservation) => state.ConfirmAsync(reservation));

    public async Task<ReservationResponse> RejectAsync(int id, ReservationRejectRequest request)
    {
        await _rejectValidator.ValidateAndThrowAsync(request);

        return await ChangeStatusAsync(id, (state, reservation) => state.RejectAsync(reservation, request.Reason.Trim()));
    }

    public Task<ReservationResponse> CompleteAsync(int id)
        => ChangeStatusAsync(id, (state, reservation) => state.CompleteAsync(reservation));

    // Tijelo zahtjeva nije obavezno: korisnik otkazuje bez razloga.
    public async Task<ReservationResponse> CancelAsync(int id, ReservationCancelRequest? request)
    {
        request ??= new ReservationCancelRequest();
        await _cancelValidator.ValidateAndThrowAsync(request);

        var reason = string.IsNullOrWhiteSpace(request.Reason) ? null : request.Reason.Trim();

        return await ChangeStatusAsync(id, (state, reservation) => state.CancelAsync(reservation, reason));
    }

    // Učitava rezervaciju sa zaključavanjem (UPDLOCK) do kraja transakcije: drugi zahtjev za istu rezervaciju
    // (npr. administrator je potvrđuje dok je korisnik otkazuje) čeka, pa vidi novi status i state machine ga odbije.
    private async Task<ReservationResponse> ChangeStatusAsync(int id, Func<BaseReservationState, Reservation, Task> action)
    {
        await using var transaction = await _dbContext.Database.BeginTransactionAsync();

        var reservation = await RestrictToCurrentUser(
                _dbContext.Reservations.FromSql($"SELECT * FROM Reservations WITH (UPDLOCK, ROWLOCK) WHERE Id = {id}"))
            .Where(x => x.Id == id)
            .FirstOrDefaultAsync()
            ?? throw new KeyNotFoundException($"Reservation with id {id} not found.");

        var state = _reservationState.GetReservationState(reservation.Status);
        await action(state, reservation);

        await _dbContext.SaveChangesAsync();
        await transaction.CommitAsync();

        return await GetByIdAsync(id);
    }

    // ---------- Pomoćne metode ----------

    private IQueryable<Reservation> RestrictToCurrentUser(IQueryable<Reservation> query)
    {
        if (_authenticatedUser.IsInRole(RoleNames.Administrator))
        {
            return query;
        }

        var userId = _authenticatedUser.GetUserId();
        return query.Where(x => x.UserId == userId);
    }

    private List<string> GetAllowedActions(ReservationResponse reservation)
        => _reservationState.GetReservationState(reservation.Status).GetAllowedActions(reservation);
}
