namespace RentACar.Model.Responses;

public class SeasonalPriceResponse
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public DateOnly StartDate { get; set; }
    public DateOnly EndDate { get; set; }
    public decimal IncreasePercentage { get; set; }
    public bool IsActive { get; set; }
}
