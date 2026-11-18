using System.Globalization;
using RentACar.Model.Enums;
using RentACar.Services.Database;

namespace RentACar.Services.Helpers;

// Tekstovi notifikacija o rezervaciji (prijava, "Notifikacije"): kreiranje, uspješno plaćanje, potvrda, odbijanje ili
// otkazivanje uz razlog, povrat novca, završetak najma uz poziv na recenziju i podsjetnik dan prije preuzimanja.
// Notifikacija se upisuje u istoj transakciji kao i promjena koju opisuje.
public static class ReservationNotifications
{
    private const int MaxMessageLength = 500;

    public static Notification Created(Reservation reservation, string vehicleName) => Create(reservation,
        "Rezervacija kreirana",
        $"Rezervacija vozila {vehicleName} za period {Period(reservation)} je kreirana. " +
        $"Ukupan iznos: {Amount(reservation.TotalPrice)} KM. Platite je u roku od {PaymentRules.PaymentDeadlineMinutes} minuta, " +
        "nakon čega čeka potvrdu administratora.");

    public static Notification Paid(Reservation reservation, string vehicleName, decimal amount) => Create(reservation,
        "Plaćanje uspješno",
        $"Uplata od {Amount(amount)} KM za rezervaciju vozila {vehicleName} za period {Period(reservation)} je uspješna. " +
        "Rezervacija čeka potvrdu administratora.");

    public static Notification Confirmed(Reservation reservation, string vehicleName) => Create(reservation,
        "Rezervacija potvrđena",
        $"Rezervacija vozila {vehicleName} za period {Period(reservation)} je potvrđena.");

    public static Notification Rejected(Reservation reservation, string vehicleName, string reason) => Create(reservation,
        "Rezervacija odbijena",
        $"Rezervacija vozila {vehicleName} za period {Period(reservation)} je odbijena. Razlog: {reason}");

    public static Notification CancelledByAdministrator(Reservation reservation, string vehicleName, string reason) => Create(reservation,
        "Rezervacija otkazana",
        $"Rezervacija vozila {vehicleName} za period {Period(reservation)} je otkazana. Razlog: {reason}");

    public static Notification CancelledByCustomer(Reservation reservation, string vehicleName) => Create(reservation,
        "Rezervacija otkazana",
        $"Otkazali ste rezervaciju vozila {vehicleName} za period {Period(reservation)}.");

    // Sistem otkazuje rezervaciju koja nije plaćena u roku (razlog se vidi i u detaljima rezervacije).
    public static Notification Expired(Reservation reservation, string vehicleName) => Create(reservation,
        "Rezervacija otkazana",
        $"Rezervacija vozila {vehicleName} za period {Period(reservation)} je otkazana. Razlog: {PaymentRules.ExpiredReason}");

    public static Notification Refunded(Reservation reservation, string vehicleName, decimal amount) => Create(reservation,
        "Povrat novca",
        $"Iznos od {Amount(amount)} KM za rezervaciju vozila {vehicleName} za period {Period(reservation)} " +
        "vraćen je na vašu karticu.");

    public static Notification PickupReminder(Reservation reservation, string vehicleName) => Create(reservation,
        "Podsjetnik za preuzimanje",
        $"Vozilo {vehicleName} preuzimate {AgencyTime.Format(reservation.PickupAt)}. " +
        $"Rok za vraćanje je {AgencyTime.Format(reservation.ReturnAt)}.");

    public static Notification Completed(Reservation reservation, string vehicleName) => Create(reservation,
        "Najam završen",
        $"Najam vozila {vehicleName} je završen. Ocijenite vozilo i ostavite recenziju u detaljima rezervacije.");

    // Naziv statusa kako ga korisnik vidi u aplikacijama.
    public static string StatusName(ReservationStatus status) => status switch
    {
        ReservationStatus.Pending => "Na čekanju",
        ReservationStatus.Confirmed => "Potvrđena",
        ReservationStatus.Completed => "Završena",
        ReservationStatus.Cancelled => "Otkazana",
        _ => status.ToString()
    };

    private static Notification Create(Reservation reservation, string title, string message) => new()
    {
        UserId = reservation.UserId,
        Title = title,
        Message = message.Length > MaxMessageLength ? message[..MaxMessageLength] : message,
        CreatedAt = DateTime.UtcNow
    };

    private static string Period(Reservation reservation)
        => $"{AgencyTime.Format(reservation.PickupAt)} – {AgencyTime.Format(reservation.ReturnAt)}";

    // Npr. "225,00".
    private static string Amount(decimal amount)
        => amount.ToString("0.00", CultureInfo.InvariantCulture).Replace('.', ',');
}
