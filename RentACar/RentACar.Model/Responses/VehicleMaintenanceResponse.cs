namespace RentACar.Model.Responses;

public class VehicleMaintenanceResponse
{
    public int Id { get; set; }
    public DateTime StartAt { get; set; }
    public DateTime EndAt { get; set; }
    public string Description { get; set; } = string.Empty;
    public decimal Cost { get; set; }

    public int VehicleId { get; set; }

    public string VehicleName { get; set; } = string.Empty;
    public string VehicleRegistrationNumber { get; set; } = string.Empty;
    public bool VehicleHasImage { get; set; }
}
