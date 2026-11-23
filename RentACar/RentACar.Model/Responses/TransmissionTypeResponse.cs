namespace RentACar.Model.Responses;

public class TransmissionTypeResponse
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;

    public string? DeleteBlockedReason { get; set; }
}
