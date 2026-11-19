using RentACar.Model.Enums;
using RentACar.Model.Messaging;
using RentACar.Services.Database;

namespace RentACar.Services.Helpers;

// Tekstovi e-mailova koje šalje Worker (prijava): potvrda i otkazivanje rezervacije te kod za reset lozinke.
public static class EmailMessages
{
    private const string Signature = "RentACar";

    // Prijava: "O potvrdi i otkazivanju rezervacije korisnik dobija i e-mail." Odbijena i neplaćena rezervacija
    // takođe prelaze u status Otkazana, pa i za njih stiže e-mail.
    public static bool IsSentFor(ReservationStatus newStatus)
        => newStatus is ReservationStatus.Confirmed or ReservationStatus.Cancelled;

    // Isti naslov i tekst kao notifikacija u aplikaciji (razlog odbijanja ili otkazivanja je u tekstu).
    public static EmailMessage ReservationStatusChanged(string email, string firstName, Notification notification) => Create(
        email,
        firstName,
        notification.Title,
        $"{notification.Message}\n\nDetalje rezervacije možete pogledati u mobilnoj aplikaciji.");

    public static EmailMessage PasswordResetCode(string email, string firstName, string code) => Create(
        email,
        firstName,
        "Kod za reset lozinke",
        $"Vaš kod za reset lozinke je: {code}\n\n" +
        $"Kod važi {PasswordResetRules.CodeValidMinutes} minuta. Unesite ga u aplikaciji zajedno s novom lozinkom.\n" +
        "Ako niste tražili reset lozinke, zanemarite ovu poruku; vaša lozinka ostaje ista.");

    private static EmailMessage Create(string email, string firstName, string subject, string text) => new()
    {
        To = email,
        ToName = firstName,
        Subject = subject,
        Body = $"Poštovani/a {firstName},\n\n{text}\n\n{Signature}"
    };
}
