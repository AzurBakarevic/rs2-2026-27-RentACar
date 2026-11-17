namespace RentACar.Services.Database;

public class Brand : IEntity
{
    public int Id { get; set; }
    public string Name { get; set; } = null!;

    public ICollection<VehicleModel> Models { get; set; } = new List<VehicleModel>();
}
