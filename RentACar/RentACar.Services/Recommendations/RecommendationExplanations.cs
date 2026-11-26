namespace RentACar.Services.Recommendations;

public static class RecommendationExplanations
{
    public const string Popular = "Često iznajmljivano vozilo.";

    public static string Collaborative(string vehicleName) => $"Preporučeno na osnovu vašeg najma vozila {vehicleName}.";

    public static string ContentBased(string vehicleName) => $"Slično vozilu {vehicleName} koje ste iznajmili.";
}
