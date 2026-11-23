using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using RentACar.Model.Exceptions;
using RentACar.Model.Requests;
using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;
using RentACar.Services.Database;
using RentACar.Services.Helpers;
using RentACar.Services.Interfaces;

namespace RentACar.Services.Implementations;

public class VehicleModelService
    : BaseCRUDService<VehicleModel, VehicleModelResponse, VehicleModelSearchObject, VehicleModelInsertRequest, VehicleModelUpdateRequest>,
      IVehicleModelService
{
    public VehicleModelService(
        RentACarDbContext dbContext,
        IMapper mapper,
        IValidator<VehicleModelInsertRequest> insertValidator,
        IValidator<VehicleModelUpdateRequest> updateValidator) : base(dbContext, mapper, insertValidator, updateValidator)
    {
    }

    protected override IQueryable<VehicleModel> ApplyFilters(IQueryable<VehicleModel> query, VehicleModelSearchObject search)
    {
        if (!string.IsNullOrWhiteSpace(search.Name))
        {
            query = query.Where(x => x.Name.Contains(search.Name));
        }

        if (search.BrandId.HasValue)
        {
            query = query.Where(x => x.BrandId == search.BrandId.Value);
        }

        return query;
    }

    protected override IQueryable<VehicleModel> ApplyOrdering(IQueryable<VehicleModel> query)
        => query.OrderBy(x => x.Brand.Name).ThenBy(x => x.Name);

    protected override Task BeforeInsertAsync(VehicleModelInsertRequest request, VehicleModel entity) => ValidateAsync(entity);

    protected override Task BeforeUpdateAsync(VehicleModelUpdateRequest request, VehicleModel entity) => ValidateAsync(entity);

    protected override async Task BeforeDeleteAsync(VehicleModel entity)
    {
        if (await _dbContext.Vehicles.AnyAsync(x => x.VehicleModelId == entity.Id))
        {
            throw new ClientException(DeleteBlockedReasons.VehicleModelInUse);
        }
    }

    private async Task ValidateAsync(VehicleModel entity)
    {
        entity.Name = entity.Name.Trim();

        if (!await _dbContext.Brands.AnyAsync(x => x.Id == entity.BrandId))
        {
            throw new ClientException("Odabrana marka ne postoji.");
        }

        if (await _dbContext.VehicleModels.AnyAsync(
                x => x.BrandId == entity.BrandId && x.Name == entity.Name && x.Id != entity.Id))
        {
            throw new ClientException("Model s ovim nazivom već postoji za odabranu marku.");
        }
    }
}
