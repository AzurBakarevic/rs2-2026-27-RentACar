using Microsoft.Extensions.Logging;
using RentACar.Model.Messaging;
using RentACar.Services.Interfaces;

namespace RentACar.Services.Implementations;

// E-mailovi nastali tokom jedne promjene (npr. potvrde rezervacije). Šalju se na RabbitMQ tek nakon commita
// transakcije, da korisnik ne dobije e-mail o promjeni koja na kraju nije spremljena. Jedna lista po zahtjevu (scoped).
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

    // Za promjenu koja nije spremljena (greška prije commita).
    public void Clear() => _messages.Clear();

    // Promjena je u ovom trenutku već spremljena, a korisnik o njoj ima i notifikaciju u aplikaciji,
    // pa neuspjelo slanje (npr. RabbitMQ nije dostupan) ne vraća grešku klijentu, nego se zapisuje u log.
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
