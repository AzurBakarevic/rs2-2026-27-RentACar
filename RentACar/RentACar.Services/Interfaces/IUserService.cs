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

    // Slika profila korisnika (administrator, desktop); KeyNotFoundException (404) ako korisnik ne postoji ili nema sliku.
    // Postavljanje provjerava veličinu, MIME tip i magic bytes (upute 5).
    Task<ImageResponse> GetImageAsync(int id);
    Task SetImageAsync(int id, ImageUploadRequest request);
    Task DeleteImageAsync(int id);

    // Vlastiti profil prijavljenog korisnika (Id iz tokena, upute 5).
    Task<UserResponse> GetProfileAsync();
    Task<UserResponse> UpdateProfileAsync(UserProfileUpdateRequest request);
    Task ChangePasswordAsync(UserPasswordChangeRequest request);

    // Vlastita slika profila (mobilna aplikacija), uz iste provjere kao kod administratora.
    Task<ImageResponse> GetProfileImageAsync();
    Task SetProfileImageAsync(ImageUploadRequest request);
    Task DeleteProfileImageAsync();

    // Reset zaboravljene lozinke kodom poslanim na e-mail (prijava).
    Task RequestPasswordResetAsync(PasswordForgotRequest request);
    Task ResetPasswordAsync(PasswordResetRequest request);
}
