using System.Text.Json;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using RabbitMQ.Client;
using RentACar.Model.Messaging;
using RentACar.Services.Interfaces;

namespace RentACar.Services.Implementations;

// Jedna RabbitMQ konekcija i jedan kanal za cijelu aplikaciju (singleton), a ne nova konekcija pri svakom slanju
// kao kod profesora (upute A.1). Konekcija se otvara pri prvom slanju i ponovo kad se prekine (npr. restart RabbitMQ-a).
// Kanal ima potvrde objave: slanje završava tek kad RabbitMQ potvrdi da je poruka u redu.
public sealed class RabbitMqEmailPublisher : IEmailPublisher, IAsyncDisposable
{
    private static readonly TimeSpan ConnectionTimeout = TimeSpan.FromSeconds(5);

    private readonly ConnectionFactory _connectionFactory;
    private readonly ILogger<RabbitMqEmailPublisher> _logger;

    // Kanal se ne koristi iz više niti istovremeno, pa slanja idu jedno po jedno.
    private readonly SemaphoreSlim _lock = new(1, 1);

    private IConnection? _connection;
    private IChannel? _channel;

    public RabbitMqEmailPublisher(IOptions<RabbitMqSettings> options, ILogger<RabbitMqEmailPublisher> logger)
    {
        var settings = options.Value;
        _logger = logger;

        _connectionFactory = new ConnectionFactory
        {
            HostName = settings.Host,
            Port = settings.Port,
            UserName = settings.Username,
            Password = settings.Password,
            ClientProvidedName = "RentACar.WebAPI",
            RequestedConnectionTimeout = ConnectionTimeout,
            // Prekinuta konekcija se ponovo otvara pri sljedećem slanju (GetChannelAsync).
            AutomaticRecoveryEnabled = false
        };
    }

    public async Task PublishAsync(EmailMessage message, CancellationToken cancellationToken = default)
    {
        var body = JsonSerializer.SerializeToUtf8Bytes(message);

        // Poruka preživi restart RabbitMQ-a (trajni red i trajna poruka).
        var properties = new BasicProperties
        {
            Persistent = true,
            ContentType = "application/json"
        };

        await _lock.WaitAsync(cancellationToken);
        try
        {
            var channel = await GetChannelAsync(cancellationToken);
            await channel.BasicPublishAsync(string.Empty, MessageQueues.Emails, mandatory: false, properties, body, cancellationToken);
        }
        finally
        {
            _lock.Release();
        }
    }

    private async Task<IChannel> GetChannelAsync(CancellationToken cancellationToken)
    {
        if (_channel is { IsOpen: true })
        {
            return _channel;
        }

        await CloseAsync();

        _connection = await _connectionFactory.CreateConnectionAsync(cancellationToken);
        _channel = await _connection.CreateChannelAsync(
            new CreateChannelOptions(publisherConfirmationsEnabled: true, publisherConfirmationTrackingEnabled: true),
            cancellationToken);

        await _channel.QueueDeclareAsync(MessageQueues.FailedEmails, durable: true, exclusive: false, autoDelete: false,
            arguments: null, cancellationToken: cancellationToken);
        await _channel.QueueDeclareAsync(MessageQueues.Emails, durable: true, exclusive: false, autoDelete: false,
            arguments: MessageQueues.EmailQueueArguments, cancellationToken: cancellationToken);

        _logger.LogInformation("Connected to RabbitMQ at {Host}:{Port}.", _connectionFactory.HostName, _connectionFactory.Port);

        return _channel;
    }

    // Prekinuta konekcija se odbacuje prije zatvaranja, pa ni greška pri zatvaranju ne sprečava novu konekciju.
    private async Task CloseAsync()
    {
        var channel = _channel;
        var connection = _connection;
        _channel = null;
        _connection = null;

        try
        {
            if (channel != null)
            {
                await channel.DisposeAsync();
            }

            if (connection != null)
            {
                await connection.DisposeAsync();
            }
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Closing the previous RabbitMQ connection failed.");
        }
    }

    public async ValueTask DisposeAsync()
    {
        await CloseAsync();
        _lock.Dispose();
    }
}
