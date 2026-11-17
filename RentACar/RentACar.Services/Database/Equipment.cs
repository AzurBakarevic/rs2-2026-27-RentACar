namespace RentACar.Services.Database;

public class Equipment
{
    public int Id { get; set; }
    public string Name { get; set; } = null!;
    public decimal PricePerDay { get; set; }
    public int Quantity { get; set; }
    public bool IsActive { get; set; } = true;

    public ICollection<ReservationEquipment> ReservationItems { get; set; } = new List<ReservationEquipment>();
}
