using RentACar.Model.Responses;

namespace RentACar.Services.Interfaces;

public interface IRecommendationService
{
    Task<List<RecommendationResponse>> GetAsync();
}
