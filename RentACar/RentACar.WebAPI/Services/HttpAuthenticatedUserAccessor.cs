using System.Security.Claims;
using RentACar.Services.Interfaces;
using RentACar.WebAPI.Services.AccessManager;

namespace RentACar.WebAPI.Services;

public class HttpAuthenticatedUserAccessor : IAuthenticatedUserAccessor
{
    private readonly IHttpContextAccessor _httpContextAccessor;

    public HttpAuthenticatedUserAccessor(IHttpContextAccessor httpContextAccessor)
    {
        _httpContextAccessor = httpContextAccessor;
    }

    public int? GetUserId()
    {
        var user = _httpContextAccessor.HttpContext?.User;
        if (user?.Identity?.IsAuthenticated != true)
        {
            return null;
        }

        return int.TryParse(user.FindFirstValue(ClaimNames.Id), out var id) ? id : null;
    }

    public bool IsInRole(string role)
    {
        return _httpContextAccessor.HttpContext?.User.IsInRole(role) == true;
    }
}
