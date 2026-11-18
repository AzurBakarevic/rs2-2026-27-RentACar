using MapsterMapper;
using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;
using RentACar.Services.Database;
using RentACar.Services.Interfaces;

namespace RentACar.Services.Implementations;

public class RoleService : BaseReadService<Role, RoleResponse, RoleSearchObject>, IRoleService
{
    public RoleService(IMapper mapper, RentACarDbContext dbContext) : base(mapper, dbContext)
    {
    }

    protected override IQueryable<Role> ApplyFilters(IQueryable<Role> query, RoleSearchObject search)
    {
        if (!string.IsNullOrWhiteSpace(search.Name))
        {
            query = query.Where(x => x.Name.Contains(search.Name));
        }

        return query;
    }

    protected override IQueryable<Role> ApplyOrdering(IQueryable<Role> query) => query.OrderBy(x => x.Name);
}
