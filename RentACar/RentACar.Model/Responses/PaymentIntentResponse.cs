namespace RentACar.Model.Responses;

// Podaci s kojima mobilna aplikacija otvara Stripe obrazac za plaćanje karticom (kao kod profesora).
// Iznos je obračunao server; aplikacija ga samo prikazuje i ne može ga promijeniti.
public class PaymentIntentResponse
{
    public int ReservationId { get; set; }
    public string ClientSecret { get; set; } = string.Empty;
    public string PublishableKey { get; set; } = string.Empty;
    public decimal Amount { get; set; }

    // Valuta po ISO 4217, malim slovima kao u Stripe-u ("bam" = KM).
    public string Currency { get; set; } = string.Empty;
}
