using MailKit.Net.Smtp;
using MailKit.Security;
using Microsoft.Extensions.Options;
using MimeKit;
using MimeKit.Text;
using RentACar.Model.Messaging;

namespace RentACar.Worker;

// Šalje e-mail preko SMTP servera iz .env-a. Za svaki e-mail otvara novu SMTP konekciju; e-mailova je malo,
// a tako prekinuta konekcija ne utiče na sljedeći e-mail.
public class EmailSender
{
    private const string SenderName = "RentACar";
    private const int ImplicitSslPort = 465;
    private const int TimeoutMilliseconds = 30_000;

    private readonly SmtpSettings _settings;

    public EmailSender(IOptions<SmtpSettings> options)
    {
        _settings = options.Value;
    }

    public async Task SendAsync(EmailMessage message, CancellationToken cancellationToken)
    {
        using var mimeMessage = new MimeMessage();
        mimeMessage.From.Add(new MailboxAddress(SenderName, _settings.FromAddress));
        mimeMessage.To.Add(new MailboxAddress(message.ToName, message.To));
        mimeMessage.Subject = message.Subject;
        mimeMessage.Body = new TextPart(TextFormat.Plain) { Text = message.Body };

        using var client = new SmtpClient { Timeout = TimeoutMilliseconds };

        await client.ConnectAsync(_settings.Host, _settings.Port, GetSocketOptions(), cancellationToken);

        if (!string.IsNullOrWhiteSpace(_settings.Username))
        {
            await client.AuthenticateAsync(_settings.Username, _settings.Password, cancellationToken);
        }

        await client.SendAsync(mimeMessage, cancellationToken);
        await client.DisconnectAsync(quit: true, cancellationToken);
    }

    // Port 465 je šifrovan od početka; ostali (npr. 587 kod Gmail-a) prelaze na šifrovanje komandom STARTTLS.
    private SecureSocketOptions GetSocketOptions()
    {
        if (!_settings.UseSsl)
        {
            return SecureSocketOptions.None;
        }

        return _settings.Port == ImplicitSslPort ? SecureSocketOptions.SslOnConnect : SecureSocketOptions.StartTls;
    }
}
