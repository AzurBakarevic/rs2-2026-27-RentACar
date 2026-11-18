namespace RentACar.Model.SearchObjects;

public class VehicleMaintenanceSearchObject : BaseSearchObject
{
    // Dio naziva marke i modela ili registracije vozila.
    public string? Text { get; set; }

    public int? VehicleId { get; set; }

    // Servisi koji bar dijelom padaju u period od From do To; za jedan dan klijent šalje početak i kraj tog dana.
    public DateTime? From { get; set; }
    public DateTime? To { get; set; }
}
