using RentACar.Model.Enums;

namespace RentACar.Model.SearchObjects;

public class PaymentSearchObject : BaseSearchObject
{
    public PaymentStatus? Status { get; set; }

    public int? ReservationId { get; set; }

    public int? UserId { get; set; }
}
