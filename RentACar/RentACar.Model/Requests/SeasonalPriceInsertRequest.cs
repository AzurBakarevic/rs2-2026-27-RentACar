namespace RentACar.Model.Requests;

// Period uključuje oba datuma (od 20.12. do 05.01. znači da su i 20.12. i 05.01. u sezoni).
public class SeasonalPriceInsertRequest
{
    public string Name { get; set; } = string.Empty;
    public DateOnly StartDate { get; set; }
    public DateOnly EndDate { get; set; }

    // Uvećanje cijene najma u procentima, npr. 20 = +20 %.
    public decimal IncreasePercentage { get; set; }

    public bool IsActive { get; set; } = true;
}
