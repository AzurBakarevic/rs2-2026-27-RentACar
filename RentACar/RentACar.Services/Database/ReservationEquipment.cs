namespace RentACar.Services.Database;

public class ReservationEquipment
{
    public int Id { get; set; }
    public int Quantity { get; set; }
    public decimal PricePerDay { get; set; }

    public int ReservationId { get; set; }
    public Reservation Reservation { get; set; } = null!;

    public int EquipmentId { get; set; }
    public Equipment Equipment { get; set; } = null!;
}
