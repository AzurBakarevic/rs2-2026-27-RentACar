using System.Security.Cryptography;

namespace RentACar.Services.Helpers;

// Reset lozinke (prijava): korisnik unese e-mail, dobije kod i s njim postavi novu lozinku.
// Rok važenja i broj pokušaja nisu u prijavi; odabrani su tako da se kod ne može pogoditi isprobavanjem.
public static class PasswordResetRules
{
    public const int CodeLength = 6;
    public const int CodeValidMinutes = 15;

    // Nakon toliko pogrešnih unosa kod prestaje važiti i treba tražiti novi.
    public const int MaxFailedAttempts = 5;

    // Novi kod za isti nalog najranije nakon ovoliko sekundi (da se sanduče ne zatrpa e-mailovima).
    public const int ResendCooldownSeconds = 60;

    public const string InvalidCodeMessage = "Kod nije ispravan ili je istekao.";

    // Kod iz RandomNumberGenerator-a, a ne System.Random (upute A.3); npr. "042517".
    public static string GenerateCode()
        => RandomNumberGenerator.GetInt32(0, (int)Math.Pow(10, CodeLength)).ToString($"D{CodeLength}");
}
