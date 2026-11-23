namespace RentACar.WebAPI.Services.AccessManager;

public class JwtSettings
{
    public const string SectionName = "Jwt";

    public const int MinKeyBytes = 32;

    public string Key { get; set; } = string.Empty;
    public string Issuer { get; set; } = string.Empty;
    public string Audience { get; set; } = string.Empty;
    public int ExpiresInMinutes { get; set; }
}
