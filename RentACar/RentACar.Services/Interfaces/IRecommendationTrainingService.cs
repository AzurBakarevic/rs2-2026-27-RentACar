namespace RentACar.Services.Interfaces;

public interface IRecommendationTrainingService
{
    Task UpdateModelAsync(CancellationToken cancellationToken);
}
