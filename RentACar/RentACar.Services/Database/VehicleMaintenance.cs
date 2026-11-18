namespace RentACar.Services.Database;

public class VehicleMaintenance : IEntity
{
    public int Id { get; set; }
    public DateTime StartAt { get; set; }
    public DateTime EndAt { get; set; }
    public string Description { get; set; } = null!;
    public decimal Cost { get; set; }

    public int VehicleId { get; set; }
    public Vehicle Vehicle { get; set; } = null!;
}
