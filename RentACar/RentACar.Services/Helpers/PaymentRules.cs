namespace RentACar.Services.Helpers;

// Pravila plaćanja iz prijave na jednom mjestu (servis za plaćanje, state machine i pozadinski poslovi).
public static class PaymentRules
{
    // Sve cijene u sistemu su u KM; Stripe ih prima kao "bam" (ISO 4217, malim slovima).
    public const string Currency = "bam";

    // Rezervacija koja nije plaćena u roku od 15 minuta od kreiranja automatski se otkazuje (prijava).
    public const int PaymentDeadlineMinutes = 15;

    public const string ExpiredReason = "Rezervacija nije plaćena u roku od 15 minuta.";

    public static DateTime GetPaymentDeadline(DateTime createdAt) => createdAt.AddMinutes(PaymentDeadlineMinutes);

    // Stripe iznose prima u najmanjoj jedinici valute (feninzi): 240,00 KM = 24000.
    public static long ToMinorUnits(decimal amount) => (long)Math.Round(amount * 100m, MidpointRounding.AwayFromZero);

    public static decimal FromMinorUnits(long amount) => amount / 100m;
}
