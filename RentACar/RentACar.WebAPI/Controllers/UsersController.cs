using Microsoft.AspNetCore.Authorization;
using RentACar.Model.Constants;
using RentACar.Model.Requests;
using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;
using RentACar.Services.Interfaces;

namespace RentACar.WebAPI.Controllers;

// Administracija korisnika (desktop): sve akcije samo za administratora (upute 5: role-based na admin endpointima).
// Vlastiti profil je u ProfileController-u.
[Authorize(Roles = RoleNames.Administrator)]
public class UsersController
    : BaseCRUDController<UserResponse, UserSearchObject, UserInsertRequest, UserUpdateRequest, IUserService>
{
    public UsersController(IUserService userService) : base(userService)
    {
    }
}
