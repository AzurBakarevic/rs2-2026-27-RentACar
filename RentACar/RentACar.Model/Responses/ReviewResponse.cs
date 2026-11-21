namespace RentACar.Model.Responses;

// Recenzija s korisnikom i vozilom iz rezervacije (prijava: korisnik, vozilo, ocjena, komentar i datum).
public class ReviewResponse
{
    public int Id { get; set; }
    public int Rating { get; set; }
    public string? Comment { get; set; }
    public DateTime CreatedAt { get; set; }

    public int ReservationId { get; set; }

    public int UserId { get; set; }
    public string UserFullName { get; set; } = string.Empty;

    public int VehicleId { get; set; }

    // Marka i model, npr. "Volkswagen Golf".
    public string VehicleName { get; set; } = string.Empty;
    public string VehicleRegistrationNumber { get; set; } = string.Empty;
}
