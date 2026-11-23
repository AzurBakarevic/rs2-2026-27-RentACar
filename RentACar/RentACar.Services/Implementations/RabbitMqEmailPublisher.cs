using System.Text.Json;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using RabbitMQ.Client;
using RentACar.Model.Messaging;
using RentACar.Services.Interfaces;

namespace RentACar.Services.Implementations;

public sealed class RabbitMqEmailPublisher : IEmailPublisher, IAsyncDisposable
{
    private static readonly TimeSpan ConnectionTimeout = TimeSpan.FromSeconds(5);

    private readonly ConnectionFactory _connectionFactory;
    private readonly ILogger<RabbitMqEmailPublisher> _logger;

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
            AutomaticRecoveryEnabled = false
        };
    }

    public async Task PublishAsync(EmailMessage message, CancellationToken cancellationToken = default)
    {
        var body = JsonSerializer.SerializeToUtf8Bytes(message);

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
