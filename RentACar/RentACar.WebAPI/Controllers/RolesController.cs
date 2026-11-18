using Microsoft.AspNetCore.Authorization;
using RentACar.Model.Constants;
using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;
using RentACar.Services.Interfaces;

namespace RentACar.WebAPI.Controllers;

// Lista uloga za formu korisnika u desktop aplikaciji: samo čitanje i samo za administratora.
[Authorize(Roles = RoleNames.Administrator)]
public class RolesController : BaseReadController<RoleResponse, RoleSearchObject, IRoleService>
{
    public RolesController(IRoleService roleService) : base(roleService)
    {
    }
}
