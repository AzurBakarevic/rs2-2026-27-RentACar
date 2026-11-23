namespace RentACar.Model.SearchObjects;

public class VehicleSearchObject : BaseSearchObject
{
    public string? Text { get; set; }

    public int? BrandId { get; set; }
    public int? VehicleModelId { get; set; }
    public int? CategoryId { get; set; }
    public int? FuelTypeId { get; set; }
    public int? TransmissionTypeId { get; set; }

    public decimal? MinPricePerDay { get; set; }
    public decimal? MaxPricePerDay { get; set; }

    public bool? IsActive { get; set; }

    public DateTime? AvailableFrom { get; set; }
    public DateTime? AvailableTo { get; set; }
}
