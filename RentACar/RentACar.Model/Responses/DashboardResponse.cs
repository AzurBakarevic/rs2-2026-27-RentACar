namespace RentACar.Model.Responses;

// Početni ekran desktop aplikacije (prijava: ključni pokazatelji i grafikon rezervacija po danima).
public class DashboardResponse
{
    // Sva vozila agencije, i deaktivirana (kao u tabeli Vozila).
    public int VehicleCount { get; set; }

    // Nalozi s ulogom Korisnik koji nisu obrisani (aktivni i deaktivirani).
    public int CustomerCount { get; set; }

    // Na čekanju i potvrđene, kao filter "aktivne" u listi rezervacija.
    public int ActiveReservationCount { get; set; }

    // Plaćene rezervacije na čekanju, koje administrator treba potvrditi ili odbiti.
    public int AwaitingConfirmationCount { get; set; }

    // Broj kreiranih rezervacija po danu za posljednjih sedam dana (po lokalnom vremenu, od najstarijeg do danas),
    // i za dane bez rezervacija.
    public List<DailyReservationCountResponse> ReservationsPerDay { get; set; } = new();
}
