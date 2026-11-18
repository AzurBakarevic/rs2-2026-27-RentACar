using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;

namespace RentACar.Services.Interfaces;

// Uloge se samo čitaju (lista za formu korisnika); mijenjaju se kroz seed, jer se njihovi nazivi koriste u [Authorize].
public interface IRoleService : IBaseReadService<RoleResponse, RoleSearchObject>
{
}
