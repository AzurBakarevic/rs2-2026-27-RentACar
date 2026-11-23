using System.Security.Cryptography;

namespace RentACar.Services.Helpers;

public static class PasswordResetRules
{
    public const int CodeLength = 6;
    public const int CodeValidMinutes = 15;

    public const int MaxFailedAttempts = 5;

    public const int ResendCooldownSeconds = 60;

    public const string InvalidCodeMessage = "Kod nije ispravan ili je istekao.";

    public static string GenerateCode()
        => RandomNumberGenerator.GetInt32(0, (int)Math.Pow(10, CodeLength)).ToString($"D{CodeLength}");
}
