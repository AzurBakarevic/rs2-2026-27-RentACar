namespace RentACar.Model.Requests;

public class SeasonalPriceUpdateRequest
{
    public string Name { get; set; } = string.Empty;
    public DateOnly StartDate { get; set; }
    public DateOnly EndDate { get; set; }
    public decimal IncreasePercentage { get; set; }

    public bool IsActive { get; set; }
}
