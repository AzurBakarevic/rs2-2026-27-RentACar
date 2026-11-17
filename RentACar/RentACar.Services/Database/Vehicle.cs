namespace RentACar.Services.Database;

public class Vehicle
{
    public int Id { get; set; }
    public string RegistrationNumber { get; set; } = null!;
    public int ProductionYear { get; set; }
    public int SeatCount { get; set; }
    public string? Description { get; set; }
    public decimal PricePerDay { get; set; }
    public byte[]? Image { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; }

    public int VehicleModelId { get; set; }
    public VehicleModel VehicleModel { get; set; } = null!;

    public int CategoryId { get; set; }
    public Category Category { get; set; } = null!;

    public int FuelTypeId { get; set; }
    public FuelType FuelType { get; set; } = null!;

    public int TransmissionTypeId { get; set; }
    public TransmissionType TransmissionType { get; set; } = null!;

    public ICollection<Reservation> Reservations { get; set; } = new List<Reservation>();
    public ICollection<VehicleMaintenance> Maintenances { get; set; } = new List<VehicleMaintenance>();
}
