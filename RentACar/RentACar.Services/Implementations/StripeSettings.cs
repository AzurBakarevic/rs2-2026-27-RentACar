namespace RentACar.Services.Implementations;

// Vrijednosti dolaze iz .env-a (Stripe__SecretKey, Stripe__PublishableKey), upute 3.3; ključevi se ne commitaju.
public class StripeSettings
{
    public const string SectionName = "Stripe";

    public string SecretKey { get; set; } = string.Empty;
    public string PublishableKey { get; set; } = string.Empty;
}
