using Microsoft.Extensions.Logging;
using RentACar.Model.Messaging;
using RentACar.Services.Interfaces;

namespace RentACar.Services.Implementations;

public class PendingEmails
{
    private readonly List<EmailMessage> _messages = [];
    private readonly IEmailPublisher _publisher;
    private readonly ILogger<PendingEmails> _logger;

    public PendingEmails(IEmailPublisher publisher, ILogger<PendingEmails> logger)
    {
        _publisher = publisher;
        _logger = logger;
    }

    public void Add(EmailMessage message) => _messages.Add(message);

    public void Clear() => _messages.Clear();

    public async Task PublishAsync()
    {
        foreach (var message in _messages)
        {
            try
            {
                await _publisher.PublishAsync(message);
                _logger.LogInformation("E-mail \"{Subject}\" queued for {Recipient}.", message.Subject, message.To);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to queue e-mail \"{Subject}\" for {Recipient}.", message.Subject, message.To);
            }
        }

        _messages.Clear();
    }
}
