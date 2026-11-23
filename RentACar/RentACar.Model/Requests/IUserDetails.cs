namespace RentACar.Model.Requests;

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
