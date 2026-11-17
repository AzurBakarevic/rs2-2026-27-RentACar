namespace RentACar.Model.Requests;

public class VehicleModelInsertRequest
{
    public string Name { get; set; } = string.Empty;
    public int BrandId { get; set; }
}
