namespace RentACar.Model.Responses;

public class ReservationCalculationResponse
{
    public int VehicleId { get; set; }
    public string VehicleName { get; set; } = string.Empty;
    public int RentalDays { get; set; }
    public decimal VehiclePricePerDay { get; set; }
    public decimal VehiclePrice { get; set; }
    public decimal SeasonalSurcharge { get; set; }
    public decimal EquipmentPrice { get; set; }
    public decimal TotalPrice { get; set; }
    public List<ReservationEquipmentResponse> Equipment { get; set; } = new();
}
