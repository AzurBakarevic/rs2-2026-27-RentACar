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

public class CategoryService
    : BaseCRUDService<Category, CategoryResponse, CategorySearchObject, CategoryInsertRequest, CategoryUpdateRequest>, ICategoryService
{
    public CategoryService(
        RentACarDbContext dbContext,
        IMapper mapper,
        IValidator<CategoryInsertRequest> insertValidator,
        IValidator<CategoryUpdateRequest> updateValidator) : base(dbContext, mapper, insertValidator, updateValidator)
    {
    }

    protected override IQueryable<Category> ApplyFilters(IQueryable<Category> query, CategorySearchObject search)
    {
        if (!string.IsNullOrWhiteSpace(search.Name))
        {
            query = query.Where(x => x.Name.Contains(search.Name));
        }

        return query;
    }

    protected override IQueryable<Category> ApplyOrdering(IQueryable<Category> query) => query.OrderBy(x => x.Name);

    protected override Task BeforeInsertAsync(CategoryInsertRequest request, Category entity) => EnsureNameIsUniqueAsync(entity);

    protected override Task BeforeUpdateAsync(CategoryUpdateRequest request, Category entity) => EnsureNameIsUniqueAsync(entity);

    protected override async Task BeforeDeleteAsync(Category entity)
    {
        if (await _dbContext.Vehicles.AnyAsync(x => x.CategoryId == entity.Id))
        {
            throw new ClientException(DeleteBlockedReasons.CategoryInUse);
        }
    }

    private async Task EnsureNameIsUniqueAsync(Category entity)
    {
        entity.Name = entity.Name.Trim();

        if (await _dbContext.Categories.AnyAsync(x => x.Name == entity.Name && x.Id != entity.Id))
        {
            throw new ClientException("Kategorija s ovim nazivom već postoji.");
        }
    }
}
