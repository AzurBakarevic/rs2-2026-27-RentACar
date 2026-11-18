using RentACar.Model.Enums;

namespace RentACar.Services.Database;

public class Reservation : IEntity
{
    public int Id { get; set; }
    public DateTime PickupAt { get; set; }
    public DateTime ReturnAt { get; set; }
    public int RentalDays { get; set; }
    public decimal VehiclePrice { get; set; }
    public decimal SeasonalSurcharge { get; set; }
    public decimal EquipmentPrice { get; set; }
    public decimal TotalPrice { get; set; }
    public ReservationStatus Status { get; set; } = ReservationStatus.Pending;
    public DateTime CreatedAt { get; set; }

    // Kada je poslan podsjetnik dan prije preuzimanja (null = još nije), da se ne pošalje dva puta.
    public DateTime? ReminderSentAt { get; set; }

    public int UserId { get; set; }
    public User User { get; set; } = null!;

    public int VehicleId { get; set; }
    public Vehicle Vehicle { get; set; } = null!;

    public Review? Review { get; set; }

    public ICollection<ReservationEquipment> Equipment { get; set; } = new List<ReservationEquipment>();
    public ICollection<ReservationStatusHistory> StatusHistory { get; set; } = new List<ReservationStatusHistory>();
    public ICollection<Payment> Payments { get; set; } = new List<Payment>();
}
