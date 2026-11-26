namespace RentACar.Services.Recommendations;

public class VehicleRentalPair
{
    public int VehicleId { get; set; }
    public int CoRentedVehicleId { get; set; }
    public float Label { get; set; }
}
