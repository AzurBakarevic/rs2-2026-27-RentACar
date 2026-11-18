using RentACar.Model.Enums;

namespace RentACar.Model.Responses;

// Podaci o uplati u detaljima rezervacije (prijava: "podaci o uplati", "stanje plaćanja").
public class ReservationPaymentResponse
{
    public int Id { get; set; }
    public PaymentStatus Status { get; set; }
    public decimal Amount { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? PaidAt { get; set; }
    public DateTime? RefundedAt { get; set; }
}
