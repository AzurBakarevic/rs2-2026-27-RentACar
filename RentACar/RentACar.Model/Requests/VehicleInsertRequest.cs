namespace RentACar.Model.Requests;

// Slika se ne šalje ovdje, nego posebno: PUT /Vehicles/{id}/Image (multipart/form-data).
public class VehicleInsertRequest
{
    public string RegistrationNumber { get; set; } = string.Empty;
    public int ProductionYear { get; set; }
    public int SeatCount { get; set; }
    public string? Description { get; set; }
    public decimal PricePerDay { get; set; }

    // Marka se ne šalje: određena je modelom.
    public int VehicleModelId { get; set; }
    public int CategoryId { get; set; }
    public int FuelTypeId { get; set; }
    public int TransmissionTypeId { get; set; }

    public bool IsActive { get; set; } = true;
}
