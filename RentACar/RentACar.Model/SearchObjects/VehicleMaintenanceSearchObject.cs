namespace RentACar.Model.SearchObjects;

public class VehicleMaintenanceSearchObject : BaseSearchObject
{
    public string? Text { get; set; }

    public int? VehicleId { get; set; }

    public DateTime? From { get; set; }
    public DateTime? To { get; set; }
}
