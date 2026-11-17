namespace RentACar.Model.Requests;

// Registracija u mobilnoj aplikaciji. Nema uloge ni statusa: klijent sebi ne smije dodijeliti
// privilegije (upute 5), pa servis uvijek postavlja ulogu Korisnik.
public class UserRegisterRequest : IUserDetails
{
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string Username { get; set; } = string.Empty;
    public string? DriverLicenseNumber { get; set; }
    public DateOnly? DriverLicenseValidUntil { get; set; }

    public string Password { get; set; } = string.Empty;
    public string PasswordConfirm { get; set; } = string.Empty;
}
