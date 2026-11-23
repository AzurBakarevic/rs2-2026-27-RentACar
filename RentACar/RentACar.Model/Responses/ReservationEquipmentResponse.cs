namespace RentACar.Model.Responses;

public class ReservationEquipmentResponse
{
    public int EquipmentId { get; set; }
    public string EquipmentName { get; set; } = string.Empty;
    public int Quantity { get; set; }

    public decimal PricePerDay { get; set; }

    public decimal TotalPrice { get; set; }
}
