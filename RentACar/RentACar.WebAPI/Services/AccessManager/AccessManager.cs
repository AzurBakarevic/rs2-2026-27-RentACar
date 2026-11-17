using System.Security.Claims;
using System.Text;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Tokens;
using RentACar.Model.Requests;
using RentACar.Model.Responses;
using RentACar.Services.Interfaces;

namespace RentACar.WebAPI.Services.AccessManager;

// Prijava i odjava. Provjeru lozinke radi UserService; ovdje se samo pravi potpisani JWT.
// Bez refresh tokena: kad token istekne (401), klijent vraća korisnika na prijavu (upute A.2).
public class AccessManager : IAccessManager
{
    private readonly IUserService _userService;
    private readonly JwtSettings _jwtSettings;

    public AccessManager(IUserService userService, IOptions<JwtSettings> jwtSettings)
    {
        _userService = userService;
        _jwtSettings = jwtSettings.Value;
    }

    public async Task<UserLoginResponse> LoginAsync(UserLoginRequest request)
    {
        var user = await _userService.AuthenticateAsync(request);
        var expiresAt = DateTime.UtcNow.AddMinutes(_jwtSettings.ExpiresInMinutes);

        var tokenDescriptor = new SecurityTokenDescriptor
        {
            Subject = new ClaimsIdentity(
            [
                new Claim(ClaimNames.Id, user.Id.ToString()),
                new Claim(ClaimNames.Username, user.Username),
                new Claim(ClaimNames.Role, user.Role),
                new Claim(ClaimNames.TokenVersion, user.TokenVersion.ToString())
            ]),
            Expires = expiresAt,
            Issuer = _jwtSettings.Issuer,
            Audience = _jwtSettings.Audience,
            SigningCredentials = new SigningCredentials(
                new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_jwtSettings.Key)),
                SecurityAlgorithms.HmacSha256)
        };

        return new UserLoginResponse
        {
            AccessToken = new JsonWebTokenHandler().CreateToken(tokenDescriptor),
            ExpiresAt = expiresAt,
            UserId = user.Id,
            Username = user.Username,
            Role = user.Role
        };
    }

    public Task LogoutAsync()
    {
        return _userService.LogoutAsync();
    }
}
