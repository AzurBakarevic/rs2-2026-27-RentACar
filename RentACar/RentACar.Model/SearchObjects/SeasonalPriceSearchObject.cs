namespace RentACar.Model.SearchObjects;

public class SeasonalPriceSearchObject : BaseSearchObject
{
    // Dio naziva (bez obzira na velika/mala slova).
    public string? Name { get; set; }

    public bool? IsActive { get; set; }
}
