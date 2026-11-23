using RentACar.Model.Enums;

namespace RentACar.Model.Responses;

public class PaymentTransactionResponse
{
    public int PaymentId { get; set; }
    public PaymentStatus Status { get; set; }
    public decimal Amount { get; set; }
    public DateTime TransactionAt { get; set; }

    public int ReservationId { get; set; }
    public DateTime PickupAt { get; set; }
    public DateTime ReturnAt { get; set; }

    public string VehicleName { get; set; } = string.Empty;

    public int UserId { get; set; }
    public string UserFullName { get; set; } = string.Empty;
}
