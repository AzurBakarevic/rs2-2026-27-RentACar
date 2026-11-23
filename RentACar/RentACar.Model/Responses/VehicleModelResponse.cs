namespace RentACar.Model.Responses;

public class VehicleModelResponse
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public int BrandId { get; set; }

    public string BrandName { get; set; } = string.Empty;

    public string? DeleteBlockedReason { get; set; }
}
