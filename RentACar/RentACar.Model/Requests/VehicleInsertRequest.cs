namespace RentACar.Model.Requests;

public class VehicleInsertRequest
{
    public string RegistrationNumber { get; set; } = string.Empty;
    public int ProductionYear { get; set; }
    public int SeatCount { get; set; }
    public string? Description { get; set; }
    public decimal PricePerDay { get; set; }

    public int VehicleModelId { get; set; }
    public int CategoryId { get; set; }
    public int FuelTypeId { get; set; }
    public int TransmissionTypeId { get; set; }

    public bool IsActive { get; set; } = true;
}
