using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using RentACar.Services.Interfaces;
using RentACar.WebAPI.Filters;
using RentACar.WebAPI.Services.AccessManager;

namespace RentACar.WebAPI.Extensions;

public static class AuthenticationExtensions
{
    public static IServiceCollection AddRentACarAuthentication(this IServiceCollection services, IConfiguration configuration)
    {
        var section = configuration.GetSection(JwtSettings.SectionName);
        var settings = section.Get<JwtSettings>() ?? new JwtSettings();
        ValidateSettings(settings);

        services.Configure<JwtSettings>(section);

        services
            .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
            .AddJwtBearer(options =>
            {
                // Claimovi ostaju pod našim nazivima (ClaimNames), pa [Authorize(Roles = ...)] čita claim "Role".
                options.MapInboundClaims = false;

                options.TokenValidationParameters = new TokenValidationParameters
                {
                    ValidateIssuerSigningKey = true,
                    IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(settings.Key)),
                    ValidateIssuer = true,
                    ValidIssuer = settings.Issuer,
                    ValidateAudience = true,
                    ValidAudience = settings.Audience,
                    ValidateLifetime = true,
                    ClockSkew = TimeSpan.Zero,
                    NameClaimType = ClaimNames.Username,
                    RoleClaimType = ClaimNames.Role
                };

                options.Events = new JwtBearerEvents
                {
                    // Potpis i rok su ispravni, ali token je možda opozvan (odjava, nova lozinka, deaktivacija, brisanje).
                    OnTokenValidated = async context =>
                    {
                        var principal = context.Principal!;
                        var userService = context.HttpContext.RequestServices.GetRequiredService<IUserService>();

                        var isValid = int.TryParse(principal.FindFirstValue(ClaimNames.Id), out var userId)
                            && int.TryParse(principal.FindFirstValue(ClaimNames.TokenVersion), out var tokenVersion)
                            && await userService.IsTokenValidAsync(userId, tokenVersion);

                        if (!isValid)
                        {
                            context.Fail("Token has been revoked.");
                        }
                    },

                    // 401 i 403 u istom obliku kao ostale greške API-ja.
                    OnChallenge = context =>
                    {
                        context.HandleResponse();
                        return ExceptionFilter.WriteErrorAsync(context.Response, StatusCodes.Status401Unauthorized,
                            "Niste prijavljeni ili je sesija istekla. Prijavite se ponovo.");
                    },

                    OnForbidden = context => ExceptionFilter.WriteErrorAsync(context.Response,
                        StatusCodes.Status403Forbidden, "Nemate pravo pristupa ovoj akciji.")
                };
            });

        services.AddAuthorization();

        return services;
    }

    // Bez ispravne konfiguracije API se ne pokreće, umjesto da padne tek pri prvoj prijavi.
    private static void ValidateSettings(JwtSettings settings)
    {
        if (Encoding.UTF8.GetByteCount(settings.Key) < JwtSettings.MinKeyBytes)
        {
            throw new InvalidOperationException(
                $"JWT key is missing or shorter than {JwtSettings.MinKeyBytes} bytes. Set Jwt__Key in the .env file.");
        }

        if (string.IsNullOrWhiteSpace(settings.Issuer) || string.IsNullOrWhiteSpace(settings.Audience))
        {
            throw new InvalidOperationException("JWT issuer or audience is missing. Set Jwt__Issuer and Jwt__Audience in the .env file.");
        }

        if (settings.ExpiresInMinutes <= 0)
        {
            throw new InvalidOperationException("JWT lifetime is missing. Set Jwt__ExpiresInMinutes in the .env file.");
        }
    }
}
