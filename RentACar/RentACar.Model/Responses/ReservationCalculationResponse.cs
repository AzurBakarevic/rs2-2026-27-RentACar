namespace RentACar.Model.Responses;

// Obračun koji korisnik vidi prije potvrde rezervacije (prijava): broj dana, cijena vozila, sezonski dodatak,
// cijena opreme i ukupan iznos. Kreiranje rezervacije računa isto, pa se upiše iznos koji je korisnik vidio.
public class ReservationCalculationResponse
{
    public int VehicleId { get; set; }
    public string VehicleName { get; set; } = string.Empty;
    public int RentalDays { get; set; }
    public decimal VehiclePricePerDay { get; set; }
    public decimal VehiclePrice { get; set; }
    public decimal SeasonalSurcharge { get; set; }
    public decimal EquipmentPrice { get; set; }
    public decimal TotalPrice { get; set; }
    public List<ReservationEquipmentResponse> Equipment { get; set; } = new();
}
