namespace RentACar.Model.Responses;

public class EquipmentResponse
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public decimal PricePerDay { get; set; }
    public int Quantity { get; set; }
    public bool IsActive { get; set; }

    public string? DeleteBlockedReason { get; set; }
}
