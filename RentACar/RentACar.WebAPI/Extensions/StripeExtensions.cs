using RentACar.Services.Implementations;
using RentACar.Services.Interfaces;
using Stripe;

namespace RentACar.WebAPI.Extensions;

public static class StripeExtensions
{
    // Stripe poziv se izvršava dok je rezervacija zaključana u bazi, pa se na odgovor ne čeka dugo
    // (Stripe biblioteka inače čeka do 80 s); uz to Stripe sam ponavlja neuspjeli zahtjev do 2 puta.
    private static readonly TimeSpan RequestTimeout = TimeSpan.FromSeconds(20);
    private const int MaxNetworkRetries = 2;

    public static IServiceCollection AddRentACarStripe(this IServiceCollection services, IConfiguration configuration)
    {
        var section = configuration.GetSection(StripeSettings.SectionName);
        var settings = section.Get<StripeSettings>() ?? new StripeSettings();
        ValidateSettings(settings);

        services.Configure<StripeSettings>(section);

        // Jedan klijent za cijelu aplikaciju (dijeli HTTP konekcije); ključ je iz .env-a, a ne statički
        // StripeConfiguration.ApiKey kao kod profesora.
        services.AddSingleton(new StripeClient(new StripeClientOptions
        {
            ApiKey = settings.SecretKey,
            HttpClient = new SystemNetHttpClient(new HttpClient { Timeout = RequestTimeout }, MaxNetworkRetries)
        }));

        services.AddScoped<IPaymentGateway, StripePaymentGateway>();

        return services;
    }

    // Bez ključeva API se ne pokreće, umjesto da padne tek pri prvom plaćanju.
    private static void ValidateSettings(StripeSettings settings)
    {
        if (!settings.SecretKey.StartsWith("sk_", StringComparison.Ordinal))
        {
            throw new InvalidOperationException("Stripe secret key is missing or invalid. Set Stripe__SecretKey (sk_...) in the .env file.");
        }

        if (!settings.PublishableKey.StartsWith("pk_", StringComparison.Ordinal))
        {
            throw new InvalidOperationException("Stripe publishable key is missing or invalid. Set Stripe__PublishableKey (pk_...) in the .env file.");
        }
    }
}
