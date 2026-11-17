namespace RentACar.Model.Requests;

// Prijavljeni korisnik mijenja vlastiti profil. Id se uzima iz tokena, ne iz zahtjeva (upute 5).
public class UserProfileUpdateRequest : IUserDetails
{
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string Username { get; set; } = string.Empty;
    public string? DriverLicenseNumber { get; set; }
    public DateOnly? DriverLicenseValidUntil { get; set; }
}
