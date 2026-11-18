namespace RentACar.Services.Interfaces;

// Pozivi prema servisu za plaćanje (Stripe). Greške servisa pretvara u PaymentGatewayException,
// pa ostatak koda ne zavisi od Stripe biblioteke.
public interface IPaymentGateway
{
    // Ključ koji mobilna aplikacija koristi za Stripe obrazac; javan je po dizajnu (nije tajna).
    string PublishableKey { get; }

    Task<GatewayPaymentIntent> CreatePaymentIntentAsync(long amount, string currency, string description,
        IDictionary<string, string> metadata);

    Task<GatewayPaymentIntent> GetPaymentIntentAsync(string paymentIntentId);

    // Poništava plaćanje koje još nije izvršeno, da se više ne može platiti (npr. rezervacija je otkazana).
    // Ako je plaćanje u međuvremenu već uspjelo, vraća njegovo stanje umjesto greške.
    Task<GatewayPaymentIntent> CancelPaymentIntentAsync(string paymentIntentId);

    // Vraća cijeli uplaćeni iznos. Isti idempotencyKey pri ponovljenom pozivu ne pravi drugi povrat.
    Task<GatewayRefund> RefundAsync(string paymentIntentId, string idempotencyKey, IDictionary<string, string> metadata);
}
