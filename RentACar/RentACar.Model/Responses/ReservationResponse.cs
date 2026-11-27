using RentACar.Model.Enums;

namespace RentACar.Model.Responses;

public class ReservationResponse
{
    public int Id { get; set; }
    public DateTime PickupAt { get; set; }
    public DateTime ReturnAt { get; set; }
    public int RentalDays { get; set; }
    public decimal VehiclePrice { get; set; }
    public decimal SeasonalSurcharge { get; set; }
    public decimal EquipmentPrice { get; set; }
    public decimal TotalPrice { get; set; }
    public ReservationStatus Status { get; set; }
    public DateTime CreatedAt { get; set; }

    public bool IsPaid { get; set; }

    public DateTime PaymentDeadline { get; set; }

    public string? CancellationReason { get; set; }

    public bool HasReview { get; set; }

    public int UserId { get; set; }
    public string UserFullName { get; set; } = string.Empty;

    public bool UserHasImage { get; set; }

    public int VehicleId { get; set; }

    public string VehicleName { get; set; } = string.Empty;
    public string VehicleRegistrationNumber { get; set; } = string.Empty;
    public string VehicleCategoryName { get; set; } = string.Empty;
    public bool VehicleHasImage { get; set; }

    public List<string> AllowedActions { get; set; } = new();

    public Dictionary<string, string> ActionBlockedReasons { get; set; } = new();

    public List<ReservationEquipmentResponse>? Equipment { get; set; }

    public ReservationPaymentResponse? Payment { get; set; }

    public List<ReservationStatusHistoryResponse>? StatusHistory { get; set; }
}
