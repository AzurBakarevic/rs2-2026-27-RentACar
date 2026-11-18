using RentACar.Model.Enums;

namespace RentACar.Model.Responses;

// Isti odgovor za listu i detalje (kao ProductResponse kod profesora): detalji (GET /Reservations/{id})
// dodatno pune opremu, podatke o uplati i historiju statusa, a u listi su ta polja null.
public class ReservationResponse
{
    public int Id { get; set; }
    public DateTime PickupAt { get; set; }
    public DateTime ReturnAt { get; set; }
    public int RentalDays { get; set; }
    public decimal VehiclePrice { get; set; }
    public decimal SeasonalSurcharge { get; set; }
    public decimal EquipmentPrice { get; set; }
    public decimal TotalPrice { get; set; }
    public ReservationStatus Status { get; set; }
    public DateTime CreatedAt { get; set; }

    // Oznaka "Plaćeno" (prijava); administrator potvrđuje samo plaćenu rezervaciju.
    public bool IsPaid { get; set; }

    // Do kada se rezervacija može platiti (15 minuta od kreiranja); neplaćena se nakon toga automatski otkazuje.
    public DateTime PaymentDeadline { get; set; }

    // Razlog odbijanja ili otkazivanja; null dok rezervacija nije otkazana ili ako razlog nije naveden.
    public string? CancellationReason { get; set; }

    public int UserId { get; set; }
    public string UserFullName { get; set; } = string.Empty;

    public int VehicleId { get; set; }

    // Marka i model, npr. "Volkswagen Golf".
    public string VehicleName { get; set; } = string.Empty;
    public string VehicleRegistrationNumber { get; set; } = string.Empty;
    public bool VehicleHasImage { get; set; }

    // Akcije koje prijavljeni korisnik sada smije izvršiti (ReservationActions), da aplikacija zna koja dugmad prikazuje.
    public List<string> AllowedActions { get; set; } = new();

    public List<ReservationEquipmentResponse>? Equipment { get; set; }

    // Uplata (plaćena, vraćena ili još otvorena); null ako plaćanje nije ni započeto.
    public ReservationPaymentResponse? Payment { get; set; }

    public List<ReservationStatusHistoryResponse>? StatusHistory { get; set; }
}
