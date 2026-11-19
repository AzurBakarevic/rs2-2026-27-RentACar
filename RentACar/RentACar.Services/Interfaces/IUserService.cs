using RentACar.Model.Requests;
using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;

namespace RentACar.Services.Interfaces;

public interface IUserService : IBaseCRUDService<UserResponse, UserSearchObject, UserInsertRequest, UserUpdateRequest>
{
    // Prijava i registracija (AccessController).
    Task<AuthenticatedUser> AuthenticateAsync(UserLoginRequest request);
    Task<UserResponse> RegisterAsync(UserRegisterRequest request);
    Task LogoutAsync();

    // Provjera tokena na svakom zahtjevu (keširano, upute 8.2).
    Task<bool> IsTokenValidAsync(int userId, int tokenVersion);

    // Vlastiti profil prijavljenog korisnika (Id iz tokena, upute 5).
    Task<UserResponse> GetProfileAsync();
    Task<UserResponse> UpdateProfileAsync(UserProfileUpdateRequest request);
    Task ChangePasswordAsync(UserPasswordChangeRequest request);

    // Reset zaboravljene lozinke kodom poslanim na e-mail (prijava).
    Task RequestPasswordResetAsync(PasswordForgotRequest request);
    Task ResetPasswordAsync(PasswordResetRequest request);
}
