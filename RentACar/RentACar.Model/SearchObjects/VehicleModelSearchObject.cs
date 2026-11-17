namespace RentACar.Model.SearchObjects;

public class VehicleModelSearchObject : BaseSearchObject
{
    // Dio naziva (bez obzira na velika/mala slova).
    public string? Name { get; set; }

    // Samo modeli jedne marke (npr. padajuća lista modela nakon izbora marke).
    public int? BrandId { get; set; }
}
