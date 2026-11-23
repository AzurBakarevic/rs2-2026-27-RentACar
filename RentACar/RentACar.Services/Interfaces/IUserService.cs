using RentACar.Model.Requests;
using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;

namespace RentACar.Services.Interfaces;

public interface IUserService : IBaseCRUDService<UserResponse, UserSearchObject, UserInsertRequest, UserUpdateRequest>
{
    Task<AuthenticatedUser> AuthenticateAsync(UserLoginRequest request);
    Task<UserResponse> RegisterAsync(UserRegisterRequest request);
    Task LogoutAsync();

    Task<bool> IsTokenValidAsync(int userId, int tokenVersion);

    Task<ImageResponse> GetImageAsync(int id);
    Task SetImageAsync(int id, ImageUploadRequest request);
    Task DeleteImageAsync(int id);

    Task<UserResponse> GetProfileAsync();
    Task<UserResponse> UpdateProfileAsync(UserProfileUpdateRequest request);
    Task ChangePasswordAsync(UserPasswordChangeRequest request);

    Task<ImageResponse> GetProfileImageAsync();
    Task SetProfileImageAsync(ImageUploadRequest request);
    Task DeleteProfileImageAsync();

    Task RequestPasswordResetAsync(PasswordForgotRequest request);
    Task ResetPasswordAsync(PasswordResetRequest request);
}
