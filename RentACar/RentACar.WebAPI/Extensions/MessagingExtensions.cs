using RentACar.Model.Messaging;
using RentACar.Services.Implementations;
using RentACar.Services.Interfaces;

namespace RentACar.WebAPI.Extensions;

public static class MessagingExtensions
{
    public static IServiceCollection AddRentACarMessaging(this IServiceCollection services, IConfiguration configuration)
    {
        var section = configuration.GetSection(RabbitMqSettings.SectionName);
        var settings = section.Get<RabbitMqSettings>() ?? new RabbitMqSettings();
        settings.Validate();

        services.Configure<RabbitMqSettings>(section);

        services.AddSingleton<IEmailPublisher, RabbitMqEmailPublisher>();
        services.AddScoped<PendingEmails>();

        return services;
    }
}
