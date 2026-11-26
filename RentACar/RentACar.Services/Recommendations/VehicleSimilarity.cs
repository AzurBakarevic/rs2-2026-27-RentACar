namespace RentACar.Services.Recommendations;

public static class VehicleSimilarity
{
    public const double CategoryWeight = 0.4;
    public const double FuelTypeWeight = 0.2;
    public const double TransmissionTypeWeight = 0.2;
    public const double PriceWeight = 0.2;

    public static double Calculate(RecommendationVehicle rented, RecommendationVehicle candidate)
    {
        var similarity = 0d;

        if (rented.CategoryId == candidate.CategoryId)
        {
            similarity += CategoryWeight;
        }

        if (rented.FuelTypeId == candidate.FuelTypeId)
        {
            similarity += FuelTypeWeight;
        }

        if (rented.TransmissionTypeId == candidate.TransmissionTypeId)
        {
            similarity += TransmissionTypeWeight;
        }

        return similarity + PriceWeight * PriceSimilarity(rented.PricePerDay, candidate.PricePerDay);
    }

    private static double PriceSimilarity(decimal first, decimal second)
    {
        var higher = Math.Max(first, second);
        return higher <= 0 ? 1 : (double)(1 - Math.Abs(first - second) / higher);
    }
}
