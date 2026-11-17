using RentACar.Model.Requests;
using RentACar.Model.Responses;

namespace RentACar.WebAPI.Services.AccessManager;

public interface IAccessManager
{
    Task<UserLoginResponse> LoginAsync(UserLoginRequest request);
    Task LogoutAsync();
}
