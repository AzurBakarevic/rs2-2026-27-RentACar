namespace RentACar.Services.Helpers;

// Zašto se akcija nad rezervacijom trenutno ne može izvršiti; null = može. Isto pravilo i isti tekst koriste
// odgovor (onemogućeno dugme s razlogom, upute 6) i greška pri pokušaju akcije.
public static class ReservationBlockedReasons
{
    public const string NotPaid = "Potvrditi se može samo plaćena rezervacija.";
    public const string NotPickedUp = "Rezervacija se može završiti tek nakon preuzimanja vozila.";
    public const string RentalEnded = "Period najma je istekao, pa se rezervacija ne može otkazati. Označite je kao završenu.";

    public static readonly string CancellationTooLate =
        $"Rezervaciju je moguće otkazati najkasnije {ReservationRules.CustomerCancellationNoticeHours} sata prije preuzimanja vozila.";

    public static string? Confirm(bool isPaid) => isPaid ? null : NotPaid;

    public static string? Complete(DateTime pickupAt, DateTime now) => now < pickupAt ? NotPickedUp : null;

    public static string? CancelByAdministrator(DateTime returnAt, DateTime now) => now >= returnAt ? RentalEnded : null;

    public static string? CancelByCustomer(DateTime pickupAt, DateTime now)
        => ReservationRules.CanCustomerCancel(pickupAt, now) ? null : CancellationTooLate;
}
