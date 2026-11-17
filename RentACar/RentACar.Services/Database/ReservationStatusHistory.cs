using RentACar.Model.Enums;

namespace RentACar.Services.Database;

public class ReservationStatusHistory
{
    public int Id { get; set; }
    public ReservationStatus? OldStatus { get; set; }
    public ReservationStatus NewStatus { get; set; }
    public string? Reason { get; set; }
    public DateTime ChangedAt { get; set; }

    public int ReservationId { get; set; }
    public Reservation Reservation { get; set; } = null!;

    // null = promjenu je izvršio sistem (npr. istek roka za plaćanje)
    public int? ChangedByUserId { get; set; }
    public User? ChangedByUser { get; set; }
}
