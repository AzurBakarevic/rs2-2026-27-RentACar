namespace RentACar.Model.Exceptions;

// Servis za plaćanje (Stripe) nije odgovorio ili je odbio zahtjev servera. Poruka je za korisnika (na bosanskom);
// ExceptionFilter je vraća kao 503, a tehnički detalji se samo zapisuju u log.
public class PaymentGatewayException : Exception
{
    public PaymentGatewayException(string message, Exception? innerException = null) : base(message, innerException)
    {
    }
}
