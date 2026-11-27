using RentACar.Model.Enums;

namespace RentACar.Model.SearchObjects;

public class ReservationSearchObject : BaseSearchObject
{
    public string? Text { get; set; }

    public int? UserId { get; set; }
    public int? VehicleId { get; set; }
    public ReservationStatus? Status { get; set; }

    public bool? IsActive { get; set; }
    public bool? IsUpcoming { get; set; }

    public DateTime? From { get; set; }
    public DateTime? To { get; set; }
}
