using RentACar.Model.Enums;

namespace RentACar.Model.Responses;

public class ReservationStatusHistoryResponse
{
    // null kod prvog zapisa (kreiranje rezervacije).
    public ReservationStatus? OldStatus { get; set; }
    public ReservationStatus NewStatus { get; set; }
    public string? Reason { get; set; }
    public DateTime ChangedAt { get; set; }

    // Ko je izvršio promjenu; null znači da ju je izvršio sistem (npr. istek roka za plaćanje).
    public int? ChangedByUserId { get; set; }
    public string? ChangedByName { get; set; }
}
