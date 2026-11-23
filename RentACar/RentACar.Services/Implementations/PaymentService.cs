using Microsoft.EntityFrameworkCore;
using RentACar.Model.Constants;
using RentACar.Model.Enums;
using RentACar.Model.Exceptions;
using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;
using RentACar.Services.Database;
using RentACar.Services.Helpers;
using RentACar.Services.Interfaces;

namespace RentACar.Services.Implementations;

public class PaymentService : IPaymentService
{
    private readonly RentACarDbContext _dbContext;
    private readonly IPaymentGateway _gateway;
    private readonly ReservationPaymentHandler _paymentHandler;
    private readonly IReservationService _reservationService;
    private readonly IAuthenticatedUserAccessor _authenticatedUser;

    public PaymentService(
        RentACarDbContext dbContext,
        IPaymentGateway gateway,
        ReservationPaymentHandler paymentHandler,
        IReservationService reservationService,
        IAuthenticatedUserAccessor authenticatedUser)
    {
        _dbContext = dbContext;
        _gateway = gateway;
        _paymentHandler = paymentHandler;
        _reservationService = reservationService;
        _authenticatedUser = authenticatedUser;
    }

    public async Task<PageResult<PaymentTransactionResponse>> GetAllAsync(PaymentSearchObject? search = null)
    {
        search ??= new PaymentSearchObject();

        var payments = _dbContext.Payments.AsNoTracking();

        if (_authenticatedUser.IsInRole(RoleNames.Administrator))
        {
            if (search.UserId.HasValue)
            {
                payments = payments.Where(x => x.Reservation.UserId == search.UserId.Value);
            }
        }
        else
        {
            var userId = _authenticatedUser.GetUserId();
            payments = payments.Where(x => x.Reservation.UserId == userId);
        }

        if (search.ReservationId.HasValue)
        {
            payments = payments.Where(x => x.ReservationId == search.ReservationId.Value);
        }

        var paid = payments
            .Where(x => x.PaidAt != null)
            .Select(x => new PaymentTransactionResponse
            {
                PaymentId = x.Id,
                Status = PaymentStatus.Paid,
                Amount = x.ChargedAmount ?? x.Amount,
                TransactionAt = x.PaidAt!.Value,
                ReservationId = x.ReservationId,
                PickupAt = x.Reservation.PickupAt,
                ReturnAt = x.Reservation.ReturnAt,
                VehicleName = x.Reservation.Vehicle.VehicleModel.Brand.Name + " " + x.Reservation.Vehicle.VehicleModel.Name,
                UserId = x.Reservation.UserId,
                UserFullName = x.Reservation.User.FirstName + " " + x.Reservation.User.LastName
            });

        var refunded = payments
            .Where(x => x.RefundedAt != null)
            .Select(x => new PaymentTransactionResponse
            {
                PaymentId = x.Id,
                Status = PaymentStatus.Refunded,
                Amount = x.ChargedAmount ?? x.Amount,
                TransactionAt = x.RefundedAt!.Value,
                ReservationId = x.ReservationId,
                PickupAt = x.Reservation.PickupAt,
                ReturnAt = x.Reservation.ReturnAt,
                VehicleName = x.Reservation.Vehicle.VehicleModel.Brand.Name + " " + x.Reservation.Vehicle.VehicleModel.Name,
                UserId = x.Reservation.UserId,
                UserFullName = x.Reservation.User.FirstName + " " + x.Reservation.User.LastName
            });

        var query = search.Status switch
        {
            PaymentStatus.Paid => paid,
            PaymentStatus.Refunded => refunded,
            null => paid.Concat(refunded),
            _ => paid.Where(x => false)
        };

        int? totalCount = null;
        if (search.IncludeTotalCount ?? false)
        {
            totalCount = await query.CountAsync();
        }

        var page = Math.Max(search.Page ?? 1, 1);
        var pageSize = Math.Clamp(search.PageSize ?? BaseSearchObject.DefaultPageSize, 1, BaseSearchObject.MaxPageSize);
        var skip = (int)Math.Min((long)(page - 1) * pageSize, int.MaxValue);

        var items = await query
            .OrderByDescending(x => x.TransactionAt)
            .ThenByDescending(x => x.PaymentId)
            .ThenByDescending(x => x.Status)
            .Skip(skip)
            .Take(pageSize)
            .ToListAsync();

        return new PageResult<PaymentTransactionResponse>
        {
            Items = items,
            TotalCount = totalCount
        };
    }

    public async Task<PaymentIntentResponse> CreatePaymentAsync(int reservationId)
    {
        await using var transaction = await _dbContext.Database.BeginTransactionAsync();

        var reservation = await LockOwnReservationAsync(reservationId);
        EnsurePending(reservation);

        var payment = await _paymentHandler.GetActivePaymentAsync(reservation.Id);
        GatewayPaymentIntent? intent = null;

        if (payment is { Status: PaymentStatus.Pending })
        {
            intent = await _gateway.GetPaymentIntentAsync(payment.StripePaymentIntentId);
            payment = await _paymentHandler.ApplyAsync(reservation, payment, intent);
        }

        if (payment is { Status: PaymentStatus.Paid })
        {
            await _dbContext.SaveChangesAsync();
            await transaction.CommitAsync();
            throw new ClientException("Rezervacija je već plaćena.");
        }

        if (DateTime.UtcNow >= PaymentRules.GetPaymentDeadline(reservation.CreatedAt))
        {
            throw new ClientException(
                $"Rok za plaćanje je istekao. Rezervacija koja nije plaćena u roku od {PaymentRules.PaymentDeadlineMinutes} minuta se otkazuje.");
        }

        if (payment == null)
        {
            intent = await _gateway.CreatePaymentIntentAsync(
                PaymentRules.ToMinorUnits(reservation.TotalPrice),
                PaymentRules.Currency,
                $"RentACar rezervacija #{reservation.Id}",
                ReservationPaymentHandler.CreateMetadata(reservation));

            _dbContext.Payments.Add(new Payment
            {
                ReservationId = reservation.Id,
                StripePaymentIntentId = intent.Id,
                Amount = reservation.TotalPrice,
                Status = PaymentStatus.Pending,
                CreatedAt = DateTime.UtcNow
            });
        }
        else if (intent!.IsProcessing)
        {
            throw new ClientException("Plaćanje se obrađuje. Provjerite status rezervacije za nekoliko trenutaka.");
        }

        await _dbContext.SaveChangesAsync();
        await transaction.CommitAsync();

        return new PaymentIntentResponse
        {
            ReservationId = reservation.Id,
            ClientSecret = intent.ClientSecret ?? string.Empty,
            PublishableKey = _gateway.PublishableKey,
            Amount = reservation.TotalPrice,
            Currency = PaymentRules.Currency
        };
    }

    public async Task<ReservationResponse> ConfirmPaymentAsync(int reservationId)
    {
        await using var transaction = await _dbContext.Database.BeginTransactionAsync();

        var reservation = await LockOwnReservationAsync(reservationId);
        var payment = await _paymentHandler.GetActivePaymentAsync(reservation.Id);

        if (payment is { Status: PaymentStatus.Pending })
        {
            var intent = await _gateway.GetPaymentIntentAsync(payment.StripePaymentIntentId);
            payment = await _paymentHandler.ApplyAsync(reservation, payment, intent);

            if (payment == null)
            {
                await _dbContext.SaveChangesAsync();
                await transaction.CommitAsync();
                throw new ClientException("Plaćanje je poništeno. Pokrenite plaćanje ponovo.");
            }

            if (payment.Status == PaymentStatus.Pending)
            {
                throw new ClientException(intent.IsProcessing
                    ? "Plaćanje se još obrađuje. Provjerite status rezervacije za nekoliko trenutaka."
                    : "Plaćanje nije završeno. Pokušajte ponovo.");
            }
        }
        else if (payment == null)
        {
            EnsurePending(reservation);
            throw new ClientException("Plaćanje za ovu rezervaciju nije započeto.");
        }

        await _dbContext.SaveChangesAsync();
        await transaction.CommitAsync();

        return await _reservationService.GetByIdAsync(reservation.Id);
    }

    private async Task<Reservation> LockOwnReservationAsync(int reservationId)
    {
        var userId = _authenticatedUser.GetUserId() ?? throw new UnauthorizedAccessException();

        return await _dbContext.Reservations
                   .FromSql($"SELECT * FROM Reservations WITH (UPDLOCK, ROWLOCK) WHERE Id = {reservationId}")
                   .Where(x => x.Id == reservationId && x.UserId == userId)
                   .FirstOrDefaultAsync()
               ?? throw new KeyNotFoundException($"Reservation with id {reservationId} not found.");
    }

    private static void EnsurePending(Reservation reservation)
    {
        if (reservation.Status != ReservationStatus.Pending)
        {
            throw new ClientException(
                $"Plaćanje nije moguće za rezervaciju sa statusom \"{ReservationNotifications.StatusName(reservation.Status)}\".");
        }
    }
}
