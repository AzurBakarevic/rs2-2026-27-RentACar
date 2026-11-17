namespace RentACar.Model.Requests;

public class VehicleModelUpdateRequest
{
    public string Name { get; set; } = string.Empty;
    public int BrandId { get; set; }
}
