namespace RentACar.Services.Helpers;

public static class PaymentRules
{
    public const string Currency = "bam";

    public const int PaymentDeadlineMinutes = 15;

    public const string ExpiredReason = "Rezervacija nije plaćena u roku od 15 minuta.";

    public static DateTime GetPaymentDeadline(DateTime createdAt) => createdAt.AddMinutes(PaymentDeadlineMinutes);

    public static long ToMinorUnits(decimal amount) => (long)Math.Round(amount * 100m, MidpointRounding.AwayFromZero);

    public static decimal FromMinorUnits(long amount) => amount / 100m;
}
