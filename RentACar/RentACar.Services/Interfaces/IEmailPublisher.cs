using RentACar.Model.Messaging;

namespace RentACar.Services.Interfaces;

public interface IEmailPublisher
{
    Task PublishAsync(EmailMessage message, CancellationToken cancellationToken = default);
}
