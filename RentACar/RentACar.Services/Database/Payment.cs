using RentACar.Model.Enums;

namespace RentACar.Services.Database;

public class Payment
{
    public int Id { get; set; }
    public string StripePaymentIntentId { get; set; } = null!;
    public decimal Amount { get; set; }
    public decimal? ChargedAmount { get; set; }
    public PaymentStatus Status { get; set; } = PaymentStatus.Pending;
    public string? StripeRefundId { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? PaidAt { get; set; }
    public DateTime? RefundedAt { get; set; }

    public int ReservationId { get; set; }
    public Reservation Reservation { get; set; } = null!;
}
