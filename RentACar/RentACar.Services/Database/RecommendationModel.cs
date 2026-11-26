namespace RentACar.Services.Database;

public class RecommendationModel : IEntity
{
    public int Id { get; set; }
    public byte[] Data { get; set; } = null!;
    public string DataHash { get; set; } = null!;
    public DateTime TrainedAt { get; set; }
}
