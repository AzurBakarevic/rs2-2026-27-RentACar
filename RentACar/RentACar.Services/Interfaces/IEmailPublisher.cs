using RentACar.Model.Messaging;

namespace RentACar.Services.Interfaces;

// Šalje e-mail poruku na RabbitMQ; e-mail zatim šalje Worker (upute 3.2).
public interface IEmailPublisher
{
    Task PublishAsync(EmailMessage message, CancellationToken cancellationToken = default);
}
