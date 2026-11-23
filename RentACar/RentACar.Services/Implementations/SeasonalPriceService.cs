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

public class SeasonalPriceService
    : BaseCRUDService<SeasonalPrice, SeasonalPriceResponse, SeasonalPriceSearchObject, SeasonalPriceInsertRequest, SeasonalPriceUpdateRequest>,
      ISeasonalPriceService
{
    public SeasonalPriceService(
        RentACarDbContext dbContext,
        IMapper mapper,
        IValidator<SeasonalPriceInsertRequest> insertValidator,
        IValidator<SeasonalPriceUpdateRequest> updateValidator) : base(dbContext, mapper, insertValidator, updateValidator)
    {
    }

    protected override IQueryable<SeasonalPrice> ApplyFilters(IQueryable<SeasonalPrice> query, SeasonalPriceSearchObject search)
    {
        if (!string.IsNullOrWhiteSpace(search.Name))
        {
            query = query.Where(x => x.Name.Contains(search.Name));
        }

        if (search.IsActive.HasValue)
        {
            query = query.Where(x => x.IsActive == search.IsActive.Value);
        }

        return query;
    }

    protected override IQueryable<SeasonalPrice> ApplyOrdering(IQueryable<SeasonalPrice> query)
        => query.OrderByDescending(x => x.StartDate).ThenBy(x => x.Name);

    protected override Task BeforeInsertAsync(SeasonalPriceInsertRequest request, SeasonalPrice entity) => ValidateAsync(entity);

    protected override Task BeforeUpdateAsync(SeasonalPriceUpdateRequest request, SeasonalPrice entity) => ValidateAsync(entity);

    private async Task ValidateAsync(SeasonalPrice entity)
    {
        entity.Name = entity.Name.Trim();

        if (entity.IsActive)
        {
            var overlapping = await _dbContext.SeasonalPrices
                .Where(x => x.IsActive
                            && x.Id != entity.Id
                            && x.StartDate <= entity.EndDate
                            && entity.StartDate <= x.EndDate)
                .Select(x => x.Name)
                .FirstOrDefaultAsync();

            if (overlapping != null)
            {
                throw new ClientException($"Period se preklapa s aktivnom sezonskom cijenom \"{overlapping}\".");
            }
        }
    }
}
