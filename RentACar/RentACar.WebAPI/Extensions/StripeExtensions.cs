using RentACar.Services.Implementations;
using RentACar.Services.Interfaces;
using Stripe;

namespace RentACar.WebAPI.Extensions;

public static class StripeExtensions
{
    private static readonly TimeSpan RequestTimeout = TimeSpan.FromSeconds(20);
    private const int MaxNetworkRetries = 2;

    public static IServiceCollection AddRentACarStripe(this IServiceCollection services, IConfiguration configuration)
    {
        var section = configuration.GetSection(StripeSettings.SectionName);
        var settings = section.Get<StripeSettings>() ?? new StripeSettings();
        ValidateSettings(settings);

        services.Configure<StripeSettings>(section);

        services.AddSingleton(new StripeClient(new StripeClientOptions
        {
            ApiKey = settings.SecretKey,
            HttpClient = new SystemNetHttpClient(new HttpClient { Timeout = RequestTimeout }, MaxNetworkRetries)
        }));

        services.AddScoped<IPaymentGateway, StripePaymentGateway>();

        return services;
    }

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
