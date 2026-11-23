namespace RentACar.Model.SearchObjects;

public class ReviewSearchObject : BaseSearchObject
{
    public string? Text { get; set; }

    public int? VehicleId { get; set; }
}
