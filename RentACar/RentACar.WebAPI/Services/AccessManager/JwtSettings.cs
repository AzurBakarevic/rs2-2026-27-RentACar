namespace RentACar.WebAPI.Services.AccessManager;

// Vrijednosti dolaze iz .env-a (Jwt__Key, Jwt__Issuer, Jwt__Audience, Jwt__ExpiresInMinutes), upute 3.3.
public class JwtSettings
{
    public const string SectionName = "Jwt";

    // HMAC-SHA256 traži ključ od najmanje 32 bajta.
    public const int MinKeyBytes = 32;

    public string Key { get; set; } = string.Empty;
    public string Issuer { get; set; } = string.Empty;
    public string Audience { get; set; } = string.Empty;
    public int ExpiresInMinutes { get; set; }
}
