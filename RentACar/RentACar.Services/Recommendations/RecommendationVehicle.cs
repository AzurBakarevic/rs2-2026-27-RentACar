namespace RentACar.Services.Recommendations;

public record RecommendationVehicle(
    int Id,
    string BrandName,
    string VehicleModelName,
    int CategoryId,
    string CategoryName,
    int FuelTypeId,
    int TransmissionTypeId,
    decimal PricePerDay,
    bool HasImage,
    bool IsActive)
{
    public string Name => $"{BrandName} {VehicleModelName}";
}
