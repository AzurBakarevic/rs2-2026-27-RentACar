namespace RentACar.Model.Responses;

public class TransmissionTypeResponse
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;

    // null = zapis se može obrisati.
    public string? DeleteBlockedReason { get; set; }
}
