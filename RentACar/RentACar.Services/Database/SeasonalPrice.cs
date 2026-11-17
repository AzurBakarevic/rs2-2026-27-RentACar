namespace RentACar.Services.Database;

public class SeasonalPrice
{
    public int Id { get; set; }
    public string Name { get; set; } = null!;
    public DateOnly StartDate { get; set; }
    public DateOnly EndDate { get; set; }
    public decimal IncreasePercentage { get; set; }
    public bool IsActive { get; set; } = true;
}
