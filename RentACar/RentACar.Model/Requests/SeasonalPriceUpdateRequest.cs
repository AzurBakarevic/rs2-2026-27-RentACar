namespace RentACar.Model.Requests;

public class SeasonalPriceUpdateRequest
{
    public string Name { get; set; } = string.Empty;
    public DateOnly StartDate { get; set; }
    public DateOnly EndDate { get; set; }
    public decimal IncreasePercentage { get; set; }

    // Neaktivna sezonska cijena se ne uračunava u cijenu i ne smeta drugim sezonama u istom periodu.
    public bool IsActive { get; set; }
}
