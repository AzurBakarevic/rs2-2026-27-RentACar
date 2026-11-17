namespace RentACar.Model.Enums;

public enum PaymentStatus
{
    Pending = 1,    // otvoreno plaćanje (PaymentIntent kreiran, uplata još nije potvrđena)
    Paid = 2,       // Plaćeno
    Refunded = 3,   // Vraćeno
    Cancelled = 4   // poništeno (npr. istekao rok od 15 minuta)
}
