using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using RentACar.Model.Exceptions;
using RentACar.Services.Interfaces;
using Stripe;

namespace RentACar.Services.Implementations;

public class StripePaymentGateway : IPaymentGateway
{
    private const string UnexpectedStateCode = "payment_intent_unexpected_state";

    private readonly StripeClient _stripeClient;
    private readonly ILogger<StripePaymentGateway> _logger;

    public StripePaymentGateway(StripeClient stripeClient, IOptions<StripeSettings> settings, ILogger<StripePaymentGateway> logger)
    {
        _stripeClient = stripeClient;
        _logger = logger;
        PublishableKey = settings.Value.PublishableKey;
    }

    public string PublishableKey { get; }

    public async Task<GatewayPaymentIntent> CreatePaymentIntentAsync(long amount, string currency, string description,
        IDictionary<string, string> metadata)
    {
        var options = new PaymentIntentCreateOptions
        {
            Amount = amount,
            Currency = currency,
            Description = description,
            Metadata = new Dictionary<string, string>(metadata),
            AutomaticPaymentMethods = new PaymentIntentAutomaticPaymentMethodsOptions
            {
                Enabled = true,
                AllowRedirects = "never"
            }
        };

        var intent = await CallAsync("create payment intent",
            () => _stripeClient.V1.PaymentIntents.CreateAsync(options),
            "Plaćanje trenutno nije moguće. Pokušajte ponovo za nekoliko minuta.");

        return Map(intent);
    }

    public async Task<GatewayPaymentIntent> GetPaymentIntentAsync(string paymentIntentId)
    {
        var intent = await CallAsync("get payment intent",
            () => _stripeClient.V1.PaymentIntents.GetAsync(paymentIntentId),
            "Provjera plaćanja trenutno nije moguća. Pokušajte ponovo za nekoliko minuta.");

        return Map(intent);
    }

    public async Task<GatewayPaymentIntent> CancelPaymentIntentAsync(string paymentIntentId)
    {
        try
        {
            return Map(await _stripeClient.V1.PaymentIntents.CancelAsync(paymentIntentId));
        }
        catch (StripeException ex) when (ex.StripeError?.Code == UnexpectedStateCode)
        {
            _logger.LogInformation("Payment intent {PaymentIntentId} could not be cancelled: {Message}", paymentIntentId, ex.Message);
            return await GetPaymentIntentAsync(paymentIntentId);
        }
        catch (Exception ex) when (IsGatewayError(ex))
        {
            throw Fail("cancel payment intent", ex, "Poništavanje plaćanja trenutno nije moguće. Pokušajte ponovo za nekoliko minuta.");
        }
    }

    public async Task<GatewayRefund> RefundAsync(string paymentIntentId, string idempotencyKey, IDictionary<string, string> metadata)
    {
        var options = new RefundCreateOptions
        {
            PaymentIntent = paymentIntentId,
            Reason = "requested_by_customer",
            Metadata = new Dictionary<string, string>(metadata)
        };

        var refund = await CallAsync("create refund",
            () => _stripeClient.V1.Refunds.CreateAsync(options, new RequestOptions { IdempotencyKey = idempotencyKey }),
            "Povrat novca trenutno nije moguć, pa promjena nije spremljena. Pokušajte ponovo za nekoliko minuta.");

        return new GatewayRefund(refund.Id, refund.Status, refund.Amount);
    }

    private async Task<T> CallAsync<T>(string operation, Func<Task<T>> call, string userMessage)
    {
        try
        {
            return await call();
        }
        catch (Exception ex) when (IsGatewayError(ex))
        {
            throw Fail(operation, ex, userMessage);
        }
    }

    private static bool IsGatewayError(Exception ex) => ex is StripeException or HttpRequestException or TaskCanceledException;

    private PaymentGatewayException Fail(string operation, Exception ex, string userMessage)
    {
        var stripeError = (ex as StripeException)?.StripeError;
        _logger.LogError(ex, "Stripe failed to {Operation} (type: {Type}, code: {Code}).", operation, stripeError?.Type, stripeError?.Code);

        return new PaymentGatewayException(userMessage, ex);
    }

    private static GatewayPaymentIntent Map(PaymentIntent intent) => new(
        intent.Id,
        intent.Status,
        intent.Amount,
        intent.AmountReceived,
        intent.Currency,
        intent.ClientSecret,
        intent.Metadata ?? new Dictionary<string, string>());
}
