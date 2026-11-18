namespace RentACar.Model.Requests;

public class EquipmentUpdateRequest
{
    public string Name { get; set; } = string.Empty;
    public decimal PricePerDay { get; set; }
    public int Quantity { get; set; }

    // false = oprema se ne nudi prilikom rezervacije.
    public bool IsActive { get; set; }
}
