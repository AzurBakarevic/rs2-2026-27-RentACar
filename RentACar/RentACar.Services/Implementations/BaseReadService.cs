using Mapster;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;
using RentACar.Services.Database;
using RentACar.Services.Interfaces;

namespace RentACar.Services.Implementations;

// Generičko čitanje. Za razliku od profesorovog BaseReadService-a, upit ostaje IQueryable do kraja:
// filtriranje, brojanje, sortiranje, straničenje i mapiranje (ProjectToType) izvršavaju se u bazi,
// pa se iz baze čitaju samo redovi i kolone koji se vraćaju (upute 8.2).
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

    // Osnovni upit nad tabelom za sve operacije; izvedeni servis ga može suziti
    // (npr. UserService izbacuje logički obrisane korisnike).
    protected virtual IQueryable<TEntity> GetQuery() => _dbContext.Set<TEntity>();

    // Uslovi iz search objekta (Where se prevodi u SQL).
    protected abstract IQueryable<TEntity> ApplyFilters(IQueryable<TEntity> query, TSearch search);

    // Straničenje traži stalan redoslijed; izvedeni servis može sortirati drugačije (npr. po nazivu).
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

        // Straničenje je uvijek uključeno; PageSize iznad MaxPageSize se svodi na MaxPageSize (upute 8.2).
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
