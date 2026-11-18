namespace RentACar.Model.Requests;

// Slika se mijenja posebno: PUT /Vehicles/{id}/Image (multipart/form-data).
public class VehicleUpdateRequest
{
    public string RegistrationNumber { get; set; } = string.Empty;
    public int ProductionYear { get; set; }
    public int SeatCount { get; set; }
    public string? Description { get; set; }
    public decimal PricePerDay { get; set; }

    public int VehicleModelId { get; set; }
    public int CategoryId { get; set; }
    public int FuelTypeId { get; set; }
    public int TransmissionTypeId { get; set; }

    // false = vozilo se uklanja iz ponude u mobilnoj aplikaciji (vozilo s rezervacijama se ne briše, nego deaktivira).
    public bool IsActive { get; set; }
}
