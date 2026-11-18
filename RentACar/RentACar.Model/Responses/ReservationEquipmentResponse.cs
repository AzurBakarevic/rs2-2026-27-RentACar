namespace RentACar.Model.Responses;

public class ReservationEquipmentResponse
{
    public int EquipmentId { get; set; }
    public string EquipmentName { get; set; } = string.Empty;
    public int Quantity { get; set; }

    // Cijena po danu u trenutku rezervacije; kasnija promjena cijene opreme ne mijenja postojeće rezervacije.
    public decimal PricePerDay { get; set; }

    // Količina × cijena po danu × broj dana najma.
    public decimal TotalPrice { get; set; }
}
