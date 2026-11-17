namespace RentACar.Model.Responses;

public class VehicleModelResponse
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public int BrandId { get; set; }

    // Mapster ga puni iz Brand.Name (spajanje naziva navigacije i svojstva).
    public string BrandName { get; set; } = string.Empty;
}
