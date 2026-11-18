using RentACar.Model.Enums;

namespace RentACar.Model.Responses;

// Jedna stavka historije plaćanja (prijava): uplata (Paid) ili povrat (Refunded) za rezervaciju.
// Vraćena uplata se pojavljuje dva puta: kao uplata i kao povrat, svaka sa svojim datumom.
public class PaymentTransactionResponse
{
    public int PaymentId { get; set; }
    public PaymentStatus Status { get; set; }
    public decimal Amount { get; set; }
    public DateTime TransactionAt { get; set; }

    public int ReservationId { get; set; }
    public DateTime PickupAt { get; set; }
    public DateTime ReturnAt { get; set; }

    // Marka i model, npr. "Volkswagen Golf".
    public string VehicleName { get; set; } = string.Empty;

    public int UserId { get; set; }
    public string UserFullName { get; set; } = string.Empty;
}
