namespace RentACar.Model.Responses;

public class FuelTypeResponse
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;

    public string? DeleteBlockedReason { get; set; }
}
