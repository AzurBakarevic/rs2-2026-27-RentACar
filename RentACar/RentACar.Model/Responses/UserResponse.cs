namespace RentACar.Model.Responses;

public class UserResponse
{
    public int Id { get; set; }
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string Username { get; set; } = string.Empty;
    public string? DriverLicenseNumber { get; set; }
    public DateOnly? DriverLicenseValidUntil { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }

    public int RoleId { get; set; }

    // Mapster ga puni iz Role.Name.
    public string RoleName { get; set; } = string.Empty;
}
