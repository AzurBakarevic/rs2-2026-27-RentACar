namespace RentACar.Services.Interfaces;

public interface IPaymentGateway
{
    string PublishableKey { get; }

    Task<GatewayPaymentIntent> CreatePaymentIntentAsync(long amount, string currency, string description,
        IDictionary<string, string> metadata);

    Task<GatewayPaymentIntent> GetPaymentIntentAsync(string paymentIntentId);

    Task<GatewayPaymentIntent> CancelPaymentIntentAsync(string paymentIntentId);

    Task<GatewayRefund> RefundAsync(string paymentIntentId, string idempotencyKey, IDictionary<string, string> metadata);
}
