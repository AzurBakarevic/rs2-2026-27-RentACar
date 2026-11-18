namespace RentACar.Model.Requests;

// Vozilo se u periodu servisa ne može rezervisati. Vremena se šalju u UTC-u (npr. "2026-11-02T08:00:00Z").
public class VehicleMaintenanceInsertRequest
{
    public int VehicleId { get; set; }
    public DateTime StartAt { get; set; }
    public DateTime EndAt { get; set; }
    public string Description { get; set; } = string.Empty;
    public decimal Cost { get; set; }
}
