namespace RentACar.Model.Requests;

public class EquipmentInsertRequest
{
    public string Name { get; set; } = string.Empty;
    public decimal PricePerDay { get; set; }

    public int Quantity { get; set; }

    public bool IsActive { get; set; } = true;
}
