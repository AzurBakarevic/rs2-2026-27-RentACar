using Mapster;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;
using RentACar.Services.Database;
using RentACar.Services.Interfaces;

namespace RentACar.Services.Implementations;

public abstract class BaseReadService<TEntity, TResponse, TSearch> : IBaseReadService<TResponse, TSearch>
    where TEntity : class, IEntity
    where TResponse : class
    where TSearch : BaseSearchObject, new()
{
    protected readonly IMapper _mapper;
    protected readonly RentACarDbContext _dbContext;

    protected BaseReadService(IMapper mapper, RentACarDbContext dbContext)
    {
        _mapper = mapper;
        _dbContext = dbContext;
    }

    protected virtual IQueryable<TEntity> GetQuery() => _dbContext.Set<TEntity>();

    protected abstract IQueryable<TEntity> ApplyFilters(IQueryable<TEntity> query, TSearch search);

    protected virtual IQueryable<TEntity> ApplyOrdering(IQueryable<TEntity> query) => query.OrderBy(x => x.Id);

    public virtual async Task<PageResult<TResponse>> GetAllAsync(TSearch? search = null)
    {
        search ??= new TSearch();

        var query = ApplyFilters(GetQuery().AsNoTracking(), search);

        int? totalCount = null;
        if (search.IncludeTotalCount ?? false)
        {
            totalCount = await query.CountAsync();
        }

        var page = Math.Max(search.Page ?? 1, 1);
        var pageSize = Math.Clamp(search.PageSize ?? BaseSearchObject.DefaultPageSize, 1, BaseSearchObject.MaxPageSize);
        var skip = (int)Math.Min((long)(page - 1) * pageSize, int.MaxValue);

        var orderedQuery = search.NewestFirst == true ? query.OrderByDescending(x => x.Id) : ApplyOrdering(query);

        var items = await orderedQuery
            .Skip(skip)
            .Take(pageSize)
            .ProjectToType<TResponse>(_mapper.Config)
            .ToListAsync();

        return new PageResult<TResponse>
        {
            Items = items,
            TotalCount = totalCount
        };
    }

    public virtual async Task<TResponse> GetByIdAsync(int id)
    {
        var item = await GetQuery()
            .AsNoTracking()
            .Where(x => x.Id == id)
            .ProjectToType<TResponse>(_mapper.Config)
            .FirstOrDefaultAsync();

        return item ?? throw new KeyNotFoundException($"{typeof(TEntity).Name} with id {id} not found.");
    }
}
