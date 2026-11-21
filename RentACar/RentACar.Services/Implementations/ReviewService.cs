using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using RentACar.Model.Constants;
using RentACar.Model.Enums;
using RentACar.Model.Exceptions;
using RentACar.Model.Requests;
using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;
using RentACar.Services.Database;
using RentACar.Services.Interfaces;

namespace RentACar.Services.Implementations;

public class ReviewService : BaseReadService<Review, ReviewResponse, ReviewSearchObject>, IReviewService
{
    private readonly IAuthenticatedUserAccessor _authenticatedUser;
    private readonly IValidator<ReviewInsertRequest> _insertValidator;

    public ReviewService(
        IMapper mapper,
        RentACarDbContext dbContext,
        IAuthenticatedUserAccessor authenticatedUser,
        IValidator<ReviewInsertRequest> insertValidator) : base(mapper, dbContext)
    {
        _authenticatedUser = authenticatedUser;
        _insertValidator = insertValidator;
    }

    // ---------- Čitanje ----------

    // Administrator vidi sve recenzije. Korisnik vidi recenzije vozila koja su u ponudi (kao i sama vozila)
    // i svoje recenzije, i kad je vozilo u međuvremenu deaktivirano.
    protected override IQueryable<Review> GetQuery()
    {
        var query = base.GetQuery();

        if (_authenticatedUser.IsInRole(RoleNames.Administrator))
        {
            return query;
        }

        var userId = _authenticatedUser.GetUserId();
        return query.Where(x => x.Reservation.Vehicle.IsActive || x.Reservation.UserId == userId);
    }

    protected override IQueryable<Review> ApplyFilters(IQueryable<Review> query, ReviewSearchObject search)
    {
        if (!string.IsNullOrWhiteSpace(search.Text))
        {
            var text = search.Text.Trim();
            query = query.Where(x => (x.Reservation.User.FirstName + " " + x.Reservation.User.LastName).Contains(text)
                                     || x.Reservation.User.Username.Contains(text)
                                     || (x.Reservation.Vehicle.VehicleModel.Brand.Name + " " + x.Reservation.Vehicle.VehicleModel.Name).Contains(text)
                                     || x.Reservation.Vehicle.RegistrationNumber.Contains(text));
        }

        if (search.VehicleId.HasValue)
        {
            query = query.Where(x => x.Reservation.VehicleId == search.VehicleId.Value);
        }

        return query;
    }

    // Najnovije prve.
    protected override IQueryable<Review> ApplyOrdering(IQueryable<Review> query)
        => query.OrderByDescending(x => x.CreatedAt).ThenByDescending(x => x.Id);

    // ---------- Dodavanje i uklanjanje ----------

    // Prijava: recenziju ostavlja korisnik nakon što rezervacija dobije status Završena, najviše jednu po rezervaciji.
    // Ako dva zahtjeva za istu rezervaciju stignu u isto vrijeme, drugi odbija jedinstveni indeks na ReservationId (409).
    public async Task<ReviewResponse> InsertAsync(ReviewInsertRequest request)
    {
        await _insertValidator.ValidateAndThrowAsync(request);

        var userId = _authenticatedUser.GetUserId()
            ?? throw new UnauthorizedAccessException("No authenticated user in the current request.");

        // Tuđa rezervacija za korisnika ne postoji (404), kao i u ReservationService-u.
        var reservation = await _dbContext.Reservations
            .AsNoTracking()
            .Where(x => x.Id == request.ReservationId && x.UserId == userId)
            .Select(x => new { x.Status, HasReview = x.Review != null })
            .FirstOrDefaultAsync()
            ?? throw new KeyNotFoundException($"Reservation with id {request.ReservationId} not found.");

        if (reservation.Status != ReservationStatus.Completed)
        {
            throw new ClientException("Recenziju možete ostaviti tek nakon završenog najma.");
        }

        if (reservation.HasReview)
        {
            throw new ClientException("Za ovu rezervaciju ste već ostavili recenziju.");
        }

        var entity = _mapper.Map<Review>(request);
        entity.Comment = string.IsNullOrWhiteSpace(request.Comment) ? null : request.Comment.Trim();
        entity.CreatedAt = DateTime.UtcNow;

        _dbContext.Reviews.Add(entity);
        await _dbContext.SaveChangesAsync();

        return await GetByIdAsync(entity.Id);
    }

    // Administrator uklanja recenziju neprimjerenog sadržaja (prijava); ona time izlazi i iz prosječne ocjene vozila.
    public async Task DeleteAsync(int id)
    {
        var deleted = await _dbContext.Reviews
            .Where(x => x.Id == id)
            .ExecuteDeleteAsync();

        if (deleted == 0)
        {
            throw new KeyNotFoundException($"Review with id {id} not found.");
        }
    }
}
