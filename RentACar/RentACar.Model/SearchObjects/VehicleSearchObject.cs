namespace RentACar.Model.SearchObjects;

public class VehicleSearchObject : BaseSearchObject
{
    // Dio naziva marke i modela (npr. "Golf" ili "Volkswagen Golf") ili registracije.
    public string? Text { get; set; }

    public int? BrandId { get; set; }
    public int? VehicleModelId { get; set; }
    public int? CategoryId { get; set; }
    public int? FuelTypeId { get; set; }
    public int? TransmissionTypeId { get; set; }

    public decimal? MinPricePerDay { get; set; }
    public decimal? MaxPricePerDay { get; set; }

    // Filter za administratora; korisnik uvijek vidi samo aktivna vozila.
    public bool? IsActive { get; set; }

    // Samo vozila slobodna u cijelom periodu (bez aktivne rezervacije i servisa). Zadaju se oba ili nijedno.
    public DateTime? AvailableFrom { get; set; }
    public DateTime? AvailableTo { get; set; }
}
