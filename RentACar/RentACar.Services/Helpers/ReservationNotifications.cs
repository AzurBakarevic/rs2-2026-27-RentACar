using System.Globalization;
using RentACar.Model.Enums;
using RentACar.Services.Database;

namespace RentACar.Services.Helpers;

// Tekstovi notifikacija o rezervaciji (prijava, "Notifikacije"): kreiranje, potvrda, odbijanje ili otkazivanje
// uz razlog i završetak najma uz poziv na recenziju. Notifikacija se upisuje u istoj transakciji kao i promjena statusa.
public static class ReservationNotifications
{
    private const int MaxMessageLength = 500;

    public static Notification Created(Reservation reservation, string vehicleName) => Create(reservation,
        "Rezervacija kreirana",
        $"Rezervacija vozila {vehicleName} za period {Period(reservation)} je kreirana. " +
        $"Ukupan iznos: {Amount(reservation.TotalPrice)} KM. Rezervacija čeka plaćanje i potvrdu.");

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
