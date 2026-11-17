namespace RentACar.Model.Requests;

// Lični podaci koji su isti u svim zahtjevima za korisnika (dodavanje, izmjena, registracija, profil),
// da se pravila validacije pišu samo jednom (UserDetailsValidator).
public interface IUserDetails
{
    string FirstName { get; }
    string LastName { get; }
    string Email { get; }
    string PhoneNumber { get; }
    string Username { get; }
    string? DriverLicenseNumber { get; }
    DateOnly? DriverLicenseValidUntil { get; }
}
