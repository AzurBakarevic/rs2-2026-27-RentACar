using RentACar.Model.Enums;

namespace RentACar.Model.Responses;

public class ReservationPaymentResponse
{
    public int Id { get; set; }
    public PaymentStatus Status { get; set; }
    public decimal Amount { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? PaidAt { get; set; }
    public DateTime? RefundedAt { get; set; }
}
