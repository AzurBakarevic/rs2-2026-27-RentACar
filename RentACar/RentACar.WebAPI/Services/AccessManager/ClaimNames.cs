namespace RentACar.WebAPI.Services.AccessManager;

// Nazivi claimova u JWT tokenu (kao profesorov ClaimNames), da se ne pišu kao stringovi po kodu.
public static class ClaimNames
{
    public const string Id = "Id";
    public const string Username = "Username";
    public const string Role = "Role";
    public const string TokenVersion = "TokenVersion";
}
