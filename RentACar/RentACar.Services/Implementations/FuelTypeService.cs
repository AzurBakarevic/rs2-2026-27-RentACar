using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using RentACar.Model.Exceptions;
using RentACar.Model.Requests;
using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;
using RentACar.Services.Database;
using RentACar.Services.Interfaces;

namespace RentACar.Services.Implementations;

public class FuelTypeService
    : BaseCRUDService<FuelType, FuelTypeResponse, FuelTypeSearchObject, FuelTypeInsertRequest, FuelTypeUpdateRequest>, IFuelTypeService
{
    public FuelTypeService(
        RentACarDbContext dbContext,
        IMapper mapper,
        IValidator<FuelTypeInsertRequest> insertValidator,
        IValidator<FuelTypeUpdateRequest> updateValidator) : base(dbContext, mapper, insertValidator, updateValidator)
    {
    }

    protected override IQueryable<FuelType> ApplyFilters(IQueryable<FuelType> query, FuelTypeSearchObject search)
    {
        if (!string.IsNullOrWhiteSpace(search.Name))
        {
            query = query.Where(x => x.Name.Contains(search.Name));
        }

        return query;
    }

    protected override IQueryable<FuelType> ApplyOrdering(IQueryable<FuelType> query) => query.OrderBy(x => x.Name);

    protected override Task BeforeInsertAsync(FuelTypeInsertRequest request, FuelType entity) => EnsureNameIsUniqueAsync(entity);

    protected override Task BeforeUpdateAsync(FuelTypeUpdateRequest request, FuelType entity) => EnsureNameIsUniqueAsync(entity);

    protected override async Task BeforeDeleteAsync(FuelType entity)
    {
        if (await _dbContext.Vehicles.AnyAsync(x => x.FuelTypeId == entity.Id))
        {
            throw new ClientException("Vrsta goriva se ne može obrisati jer je koriste vozila.");
        }
    }

    private async Task EnsureNameIsUniqueAsync(FuelType entity)
    {
        entity.Name = entity.Name.Trim();

        if (await _dbContext.FuelTypes.AnyAsync(x => x.Name == entity.Name && x.Id != entity.Id))
        {
            throw new ClientException("Vrsta goriva s ovim nazivom već postoji.");
        }
    }
}
