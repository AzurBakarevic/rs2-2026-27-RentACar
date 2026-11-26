using RentACar.Model.Enums;

namespace RentACar.Model.Responses;

public class RecommendationResponse
{
    public int VehicleId { get; set; }
    public string BrandName { get; set; } = string.Empty;
    public string VehicleModelName { get; set; } = string.Empty;
    public string CategoryName { get; set; } = string.Empty;
    public decimal PricePerDay { get; set; }
    public bool HasImage { get; set; }
    public RecommendationType Type { get; set; }
    public string Explanation { get; set; } = string.Empty;
}
