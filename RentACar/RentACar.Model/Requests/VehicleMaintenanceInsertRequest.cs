namespace RentACar.Model.Requests;

public class VehicleMaintenanceInsertRequest
{
    public int VehicleId { get; set; }
    public DateTime StartAt { get; set; }
    public DateTime EndAt { get; set; }
    public string Description { get; set; } = string.Empty;
    public decimal Cost { get; set; }
}
