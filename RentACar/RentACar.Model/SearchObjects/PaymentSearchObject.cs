using RentACar.Model.Enums;

namespace RentACar.Model.SearchObjects;

public class PaymentSearchObject : BaseSearchObject
{
    // Paid = samo uplate, Refunded = samo povrati; bez vrijednosti obje vrste.
    public PaymentStatus? Status { get; set; }

    public int? ReservationId { get; set; }

    // Samo za administratora; korisnik uvijek vidi samo svoje transakcije.
    public int? UserId { get; set; }
}
