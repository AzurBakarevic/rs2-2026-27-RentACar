namespace RentACar.Model.Requests;

// Korisnik se uzima iz tokena (upute 5), a cijenu računa server (prijava). Vremena se šalju u UTC-u
// (npr. "2026-12-01T08:00:00Z"). Isti zahtjev koristi i obračun prije potvrde (POST /Reservations/Calculate).
public class ReservationInsertRequest
{
    public int VehicleId { get; set; }
    public DateTime PickupAt { get; set; }
    public DateTime ReturnAt { get; set; }

    // Dodatna oprema s količinom; može biti prazna.
    public List<ReservationEquipmentRequest>? Equipment { get; set; }
}
