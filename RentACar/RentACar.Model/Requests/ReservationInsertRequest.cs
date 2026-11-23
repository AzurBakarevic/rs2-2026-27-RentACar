namespace RentACar.Model.Requests;

public class ReservationInsertRequest
{
    public int VehicleId { get; set; }
    public DateTime PickupAt { get; set; }
    public DateTime ReturnAt { get; set; }

    public List<ReservationEquipmentRequest>? Equipment { get; set; }
}
