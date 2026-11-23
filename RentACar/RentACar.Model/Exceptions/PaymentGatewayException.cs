namespace RentACar.Model.Exceptions;

public class PaymentGatewayException : Exception
{
    public PaymentGatewayException(string message, Exception? innerException = null) : base(message, innerException)
    {
    }
}
