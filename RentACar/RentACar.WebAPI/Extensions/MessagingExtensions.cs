using RentACar.Model.Messaging;
using RentACar.Services.Implementations;
using RentACar.Services.Interfaces;

namespace RentACar.WebAPI.Extensions;

public static class MessagingExtensions
{
    // API šalje poruke na RabbitMQ, a e-mail šalje poseban servis RentACar.Worker (upute 3.2).
    public static IServiceCollection AddRentACarMessaging(this IServiceCollection services, IConfiguration configuration)
    {
        var section = configuration.GetSection(RabbitMqSettings.SectionName);
        var settings = section.Get<RabbitMqSettings>() ?? new RabbitMqSettings();
        settings.Validate();

        services.Configure<RabbitMqSettings>(section);

        // Jedna konekcija za cijelu aplikaciju (upute A.1).
        services.AddSingleton<IEmailPublisher, RabbitMqEmailPublisher>();
        services.AddScoped<PendingEmails>();

        return services;
    }
}
