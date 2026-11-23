using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using RentACar.Model.Constants;
using RentACar.Model.Exceptions;
using RentACar.Model.Requests;
using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;
using RentACar.Services.Database;
using RentACar.Services.Helpers;
using RentACar.Services.Interfaces;

namespace RentACar.Services.Implementations;

public class VehicleService
    : BaseCRUDService<Vehicle, VehicleResponse, VehicleSearchObject, VehicleInsertRequest, VehicleUpdateRequest>, IVehicleService
{
    private readonly IValidator<ImageUploadRequest> _imageValidator;
    private readonly IAuthenticatedUserAccessor _authenticatedUser;

    public VehicleService(
        RentACarDbContext dbContext,
        IMapper mapper,
        IValidator<VehicleInsertRequest> insertValidator,
        IValidator<VehicleUpdateRequest> updateValidator,
        IValidator<ImageUploadRequest> imageValidator,
        IAuthenticatedUserAccessor authenticatedUser) : base(dbContext, mapper, insertValidator, updateValidator)
    {
        _imageValidator = imageValidator;
        _authenticatedUser = authenticatedUser;
    }

    protected override IQueryable<Vehicle> GetQuery()
    {
        var query = base.GetQuery();
        return _authenticatedUser.IsInRole(RoleNames.Administrator) ? query : query.Where(x => x.IsActive);
    }

    protected override IQueryable<Vehicle> ApplyFilters(IQueryable<Vehicle> query, VehicleSearchObject search)
    {
        if (!string.IsNullOrWhiteSpace(search.Text))
        {
            var text = search.Text.Trim();
            query = query.Where(x => x.RegistrationNumber.Contains(text)
                                     || (x.VehicleModel.Brand.Name + " " + x.VehicleModel.Name).Contains(text));
        }

        if (search.BrandId.HasValue)
        {
            query = query.Where(x => x.VehicleModel.BrandId == search.BrandId.Value);
        }

        if (search.VehicleModelId.HasValue)
        {
            query = query.Where(x => x.VehicleModelId == search.VehicleModelId.Value);
        }

        if (search.CategoryId.HasValue)
        {
            query = query.Where(x => x.CategoryId == search.CategoryId.Value);
        }

        if (search.FuelTypeId.HasValue)
        {
            query = query.Where(x => x.FuelTypeId == search.FuelTypeId.Value);
        }

        if (search.TransmissionTypeId.HasValue)
        {
            query = query.Where(x => x.TransmissionTypeId == search.TransmissionTypeId.Value);
        }

        if (search.MinPricePerDay.HasValue)
        {
            query = query.Where(x => x.PricePerDay >= search.MinPricePerDay.Value);
        }

        if (search.MaxPricePerDay.HasValue)
        {
            query = query.Where(x => x.PricePerDay <= search.MaxPricePerDay.Value);
        }

        if (search.IsActive.HasValue)
        {
            query = query.Where(x => x.IsActive == search.IsActive.Value);
        }

        if (search.AvailableFrom.HasValue || search.AvailableTo.HasValue)
        {
            if (!search.AvailableFrom.HasValue || !search.AvailableTo.HasValue)
            {
                throw new ClientException("Odaberite vrijeme preuzimanja i vraćanja vozila.");
            }

            var from = search.AvailableFrom.Value;
            var to = search.AvailableTo.Value;

            if (from >= to)
            {
                throw new ClientException("Vrijeme vraćanja mora biti poslije vremena preuzimanja.");
            }

            query = query.Where(x =>
                !x.Reservations.Any(r => ReservationStatuses.Active.Contains(r.Status) && r.PickupAt < to && from < r.ReturnAt)
                && !x.Maintenances.Any(m => m.StartAt < to && from < m.EndAt));
        }

        return query;
    }

    protected override IQueryable<Vehicle> ApplyOrdering(IQueryable<Vehicle> query)
        => query.OrderBy(x => x.VehicleModel.Brand.Name)
            .ThenBy(x => x.VehicleModel.Name)
            .ThenBy(x => x.RegistrationNumber);

    protected override Vehicle MapInsertRequestToEntity(VehicleInsertRequest request)
    {
        var entity = base.MapInsertRequestToEntity(request);
        entity.CreatedAt = DateTime.UtcNow;
        return entity;
    }

    protected override Task BeforeInsertAsync(VehicleInsertRequest request, Vehicle entity) => ValidateAsync(entity);

    protected override Task BeforeUpdateAsync(VehicleUpdateRequest request, Vehicle entity) => ValidateAsync(entity);

    protected override async Task BeforeDeleteAsync(Vehicle entity)
    {
        if (await _dbContext.Reservations.AnyAsync(x => x.VehicleId == entity.Id))
        {
            throw new ClientException(DeleteBlockedReasons.VehicleHasReservations);
        }
    }

    public async Task<ImageResponse> GetImageAsync(int id)
    {
        var image = await _dbContext.Vehicles
            .AsNoTracking()
            .Where(x => x.Id == id)
            .Select(x => x.Image)
            .FirstOrDefaultAsync();

        if (image == null || image.Length == 0)
        {
            throw new KeyNotFoundException($"Image for vehicle with id {id} not found.");
        }

        return new ImageResponse
        {
            Content = image,
            ContentType = ImageFormat.DetectContentType(image) ?? "application/octet-stream"
        };
    }

    public async Task SetImageAsync(int id, ImageUploadRequest request)
    {
        await _imageValidator.ValidateAndThrowAsync(request);

        var updated = await _dbContext.Vehicles
            .Where(x => x.Id == id)
            .ExecuteUpdateAsync(s => s.SetProperty(x => x.Image, request.Content));

        if (updated == 0)
        {
            throw new KeyNotFoundException($"Vehicle with id {id} not found.");
        }
    }

    private async Task ValidateAsync(Vehicle entity)
    {
        entity.RegistrationNumber = entity.RegistrationNumber.Trim().ToUpperInvariant();
        entity.Description = string.IsNullOrWhiteSpace(entity.Description) ? null : entity.Description.Trim();

        if (!await _dbContext.VehicleModels.AnyAsync(x => x.Id == entity.VehicleModelId))
        {
            throw new ClientException("Odabrani model ne postoji.");
        }

        if (!await _dbContext.Categories.AnyAsync(x => x.Id == entity.CategoryId))
        {
            throw new ClientException("Odabrana kategorija ne postoji.");
        }

        if (!await _dbContext.FuelTypes.AnyAsync(x => x.Id == entity.FuelTypeId))
        {
            throw new ClientException("Odabrana vrsta goriva ne postoji.");
        }

        if (!await _dbContext.TransmissionTypes.AnyAsync(x => x.Id == entity.TransmissionTypeId))
        {
            throw new ClientException("Odabrana vrsta mjenjača ne postoji.");
        }

        if (await _dbContext.Vehicles.AnyAsync(x => x.RegistrationNumber == entity.RegistrationNumber && x.Id != entity.Id))
        {
            throw new ClientException("Vozilo s ovom registracijom već postoji.");
        }
    }
}
