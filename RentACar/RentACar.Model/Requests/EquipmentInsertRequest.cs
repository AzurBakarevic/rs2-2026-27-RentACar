namespace RentACar.Model.Requests;

public class EquipmentInsertRequest
{
    public string Name { get; set; } = string.Empty;
    public decimal PricePerDay { get; set; }

    // Ukupan broj komada koje agencija ima.
    public int Quantity { get; set; }

    public bool IsActive { get; set; } = true;
}
