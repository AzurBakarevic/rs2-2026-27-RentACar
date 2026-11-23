using RentACar.Model.Enums;

namespace RentACar.Model.Responses;

public class ReservationStatusHistoryResponse
{
    public ReservationStatus? OldStatus { get; set; }
    public ReservationStatus NewStatus { get; set; }
    public string? Reason { get; set; }
    public DateTime ChangedAt { get; set; }

    public int? ChangedByUserId { get; set; }
    public string? ChangedByName { get; set; }
}
