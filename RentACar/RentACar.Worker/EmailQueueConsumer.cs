using System.Text.Json;
using Microsoft.Extensions.Options;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using RabbitMQ.Client.Exceptions;
using RentACar.Model.Messaging;

namespace RentACar.Worker;

// Čita e-mail poruke koje API šalje na RabbitMQ i šalje ih korisnicima (upute 3.2).
// AsyncEventingBasicConsumer jer je obrada poruke asinhrona (upute A.1). Poruka se potvrđuje (ack) tek kad je
// e-mail poslan. Neuspjelo slanje se ponavlja nakon 1, 2, 4 i 8 sekundi (upute A.1), a ako ni tada ne uspije,
// poruka prelazi u red neuspjelih (rentacar.emails.failed), gdje ostaje za pregled.
public class EmailQueueConsumer : BackgroundService
{
    private static readonly TimeSpan[] RetryDelays =
    [
        TimeSpan.FromSeconds(1),
        TimeSpan.FromSeconds(2),
        TimeSpan.FromSeconds(4),
        TimeSpan.FromSeconds(8)
    ];

    // Pauza između pokušaja povezivanja na RabbitMQ raste do ove granice.
    private static readonly TimeSpan MaxConnectDelay = TimeSpan.FromSeconds(30);

    private readonly RabbitMqSettings _settings;
    private readonly EmailSender _emailSender;
    private readonly ILogger<EmailQueueConsumer> _logger;

    public EmailQueueConsumer(IOptions<RabbitMqSettings> options, EmailSender emailSender, ILogger<EmailQueueConsumer> logger)
    {
        _settings = options.Value;
        _emailSender = emailSender;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        try
        {
            await using var connection = await ConnectAsync(stoppingToken);
            await using var channel = await connection.CreateChannelAsync(cancellationToken: stoppingToken);

            await channel.QueueDeclareAsync(MessageQueues.FailedEmails, durable: true, exclusive: false, autoDelete: false,
                arguments: null, cancellationToken: stoppingToken);
            await channel.QueueDeclareAsync(MessageQueues.Emails, durable: true, exclusive: false, autoDelete: false,
                arguments: MessageQueues.EmailQueueArguments, cancellationToken: stoppingToken);

            // Jedna poruka odjednom: sljedeća stiže tek kad je prethodna potvrđena ili odbačena.
            await channel.BasicQosAsync(prefetchSize: 0, prefetchCount: 1, global: false, stoppingToken);

            var consumer = new AsyncEventingBasicConsumer(channel);
            consumer.ReceivedAsync += (_, args) => HandleMessageAsync(channel, args, stoppingToken);
            await channel.BasicConsumeAsync(MessageQueues.Emails, autoAck: false, consumer, stoppingToken);

            _logger.LogInformation("Listening for e-mails on queue {Queue}.", MessageQueues.Emails);

            await Task.Delay(Timeout.Infinite, stoppingToken);
        }
        catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
        {
            _logger.LogInformation("E-mail worker is stopping.");
        }
        // Worker ne smije prestati raditi bez zapisa u logu (upute A.1); Docker ga zatim ponovo pokreće.
        catch (Exception ex)
        {
            _logger.LogCritical(ex, "E-mail worker stopped because of an unexpected error.");
            throw;
        }
    }

    // RabbitMQ se može pokrenuti nakon Worker-a, pa se povezivanje ponavlja dok ne uspije.
    // Kasnije prekide konekcije RabbitMQ.Client sam obnavlja (automatic recovery), a ovdje se samo zapisuju.
    private async Task<IConnection> ConnectAsync(CancellationToken stoppingToken)
    {
        var factory = new ConnectionFactory
        {
            HostName = _settings.Host,
            Port = _settings.Port,
            UserName = _settings.Username,
            Password = _settings.Password,
            ClientProvidedName = "RentACar.Worker"
        };

        var delay = RetryDelays[0];

        while (true)
        {
            try
            {
                var connection = await factory.CreateConnectionAsync(stoppingToken);
                _logger.LogInformation("Connected to RabbitMQ at {Host}:{Port}.", _settings.Host, _settings.Port);

                connection.ConnectionShutdownAsync += (_, args) =>
                {
                    if (args.Initiator != ShutdownInitiator.Application)
                    {
                        _logger.LogWarning("RabbitMQ connection lost: {Reason}", args.ReplyText);
                    }
                    return Task.CompletedTask;
                };
                connection.RecoverySucceededAsync += (_, _) =>
                {
                    _logger.LogInformation("RabbitMQ connection recovered.");
                    return Task.CompletedTask;
                };
                connection.ConnectionRecoveryErrorAsync += (_, args) =>
                {
                    _logger.LogError(args.Exception, "RabbitMQ connection recovery failed; trying again.");
                    return Task.CompletedTask;
                };

                return connection;
            }
            catch (BrokerUnreachableException ex)
            {
                _logger.LogWarning("RabbitMQ at {Host}:{Port} is not reachable ({Reason}); retrying in {Delay} s.",
                    _settings.Host, _settings.Port, ex.InnerException?.Message ?? ex.Message, delay.TotalSeconds);

                await Task.Delay(delay, stoppingToken);
                delay = delay * 2 < MaxConnectDelay ? delay * 2 : MaxConnectDelay;
            }
        }
    }

    private async Task HandleMessageAsync(IChannel channel, BasicDeliverEventArgs args, CancellationToken stoppingToken)
    {
        var message = Deserialize(args);
        if (message == null)
        {
            await channel.BasicNackAsync(args.DeliveryTag, multiple: false, requeue: false);
            return;
        }

        try
        {
            await SendWithRetryAsync(message, stoppingToken);
            await channel.BasicAckAsync(args.DeliveryTag, multiple: false);

            _logger.LogInformation("E-mail \"{Subject}\" sent to {Recipient}.", message.Subject, message.To);
        }
        catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
        {
            // Bez potvrde: RabbitMQ vraća poruku u red, pa se e-mail šalje kad se Worker ponovo pokrene.
            _logger.LogInformation("E-mail \"{Subject}\" not sent yet because the worker is stopping; it stays in the queue.",
                message.Subject);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "E-mail \"{Subject}\" to {Recipient} failed after {Attempts} attempts; moved to queue {Queue}.",
                message.Subject, message.To, RetryDelays.Length + 1, MessageQueues.FailedEmails);

            await channel.BasicNackAsync(args.DeliveryTag, multiple: false, requeue: false);
        }
    }

    private async Task SendWithRetryAsync(EmailMessage message, CancellationToken stoppingToken)
    {
        for (var attempt = 1; ; attempt++)
        {
            try
            {
                await _emailSender.SendAsync(message, stoppingToken);
                return;
            }
            catch (Exception ex) when (!stoppingToken.IsCancellationRequested && attempt <= RetryDelays.Length)
            {
                var delay = RetryDelays[attempt - 1];
                _logger.LogWarning(ex, "Sending e-mail \"{Subject}\" to {Recipient} failed (attempt {Attempt}); retrying in {Delay} s.",
                    message.Subject, message.To, attempt, delay.TotalSeconds);

                await Task.Delay(delay, stoppingToken);
            }
        }
    }

    // Poruka koja nije e-mail (neispravan JSON ili bez primaoca) ne može uspjeti ni ponovnim pokušajem,
    // pa odmah ide u red neuspjelih.
    private EmailMessage? Deserialize(BasicDeliverEventArgs args)
    {
        try
        {
            var message = JsonSerializer.Deserialize<EmailMessage>(args.Body.Span);
            if (message != null && !string.IsNullOrWhiteSpace(message.To))
            {
                return message;
            }

            _logger.LogError("Message {DeliveryTag} has no recipient; moved to queue {Queue}.", args.DeliveryTag, MessageQueues.FailedEmails);
        }
        catch (JsonException ex)
        {
            _logger.LogError(ex, "Message {DeliveryTag} is not a valid e-mail message; moved to queue {Queue}.",
                args.DeliveryTag, MessageQueues.FailedEmails);
        }

        return null;
    }
}
