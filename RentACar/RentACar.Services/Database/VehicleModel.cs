namespace RentACar.Services.Database;

public class VehicleModel
{
    public int Id { get; set; }
    public string Name { get; set; } = null!;

    public int BrandId { get; set; }
    public Brand Brand { get; set; } = null!;

    public ICollection<Vehicle> Vehicles { get; set; } = new List<Vehicle>();
}
