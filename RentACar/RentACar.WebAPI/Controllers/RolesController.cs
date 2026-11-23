using Microsoft.AspNetCore.Authorization;
using RentACar.Model.Constants;
using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;
using RentACar.Services.Interfaces;

namespace RentACar.WebAPI.Controllers;

[Authorize(Roles = RoleNames.Administrator)]
public class RolesController : BaseReadController<RoleResponse, RoleSearchObject, IRoleService>
{
    public RolesController(IRoleService roleService) : base(roleService)
    {
    }
}
