namespace RentACar.Services.Database;

public class TransmissionType
{
    public int Id { get; set; }
    public string Name { get; set; } = null!;

    public ICollection<Vehicle> Vehicles { get; set; } = new List<Vehicle>();
}
