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

public class BrandService
    : BaseCRUDService<Brand, BrandResponse, BrandSearchObject, BrandInsertRequest, BrandUpdateRequest>, IBrandService
{
    public BrandService(
        RentACarDbContext dbContext,
        IMapper mapper,
        IValidator<BrandInsertRequest> insertValidator,
        IValidator<BrandUpdateRequest> updateValidator) : base(dbContext, mapper, insertValidator, updateValidator)
    {
    }

    protected override IQueryable<Brand> ApplyFilters(IQueryable<Brand> query, BrandSearchObject search)
    {
        if (!string.IsNullOrWhiteSpace(search.Name))
        {
            query = query.Where(x => x.Name.Contains(search.Name));
        }

        return query;
    }

    protected override IQueryable<Brand> ApplyOrdering(IQueryable<Brand> query) => query.OrderBy(x => x.Name);

    protected override Task BeforeInsertAsync(BrandInsertRequest request, Brand entity) => EnsureNameIsUniqueAsync(entity);

    protected override Task BeforeUpdateAsync(BrandUpdateRequest request, Brand entity) => EnsureNameIsUniqueAsync(entity);

    protected override async Task BeforeDeleteAsync(Brand entity)
    {
        if (await _dbContext.VehicleModels.AnyAsync(x => x.BrandId == entity.Id))
        {
            throw new ClientException(DeleteBlockedReasons.BrandHasModels);
        }
    }

    private async Task EnsureNameIsUniqueAsync(Brand entity)
    {
        entity.Name = entity.Name.Trim();

        if (await _dbContext.Brands.AnyAsync(x => x.Name == entity.Name && x.Id != entity.Id))
        {
            throw new ClientException("Marka s ovim nazivom već postoji.");
        }
    }
}
