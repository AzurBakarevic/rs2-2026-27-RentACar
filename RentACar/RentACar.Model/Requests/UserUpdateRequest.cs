namespace RentACar.Model.Requests;

public class UserUpdateRequest : IUserDetails
{
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string Username { get; set; } = string.Empty;
    public string? DriverLicenseNumber { get; set; }
    public DateOnly? DriverLicenseValidUntil { get; set; }

    public string? Password { get; set; }
    public string? PasswordConfirm { get; set; }

    public int RoleId { get; set; }
    public bool IsActive { get; set; }
}
