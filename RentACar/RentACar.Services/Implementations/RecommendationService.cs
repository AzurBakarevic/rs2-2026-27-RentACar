using Microsoft.EntityFrameworkCore;
using RentACar.Model.Enums;
using RentACar.Model.Responses;
using RentACar.Services.Database;
using RentACar.Services.Interfaces;
using RentACar.Services.Recommendations;

namespace RentACar.Services.Implementations;

public class RecommendationService : IRecommendationService
{
    private readonly RentACarDbContext _dbContext;
    private readonly IAuthenticatedUserAccessor _authenticatedUser;
    private readonly RecommendationModelCache _modelCache;

    public RecommendationService(RentACarDbContext dbContext, IAuthenticatedUserAccessor authenticatedUser,
        RecommendationModelCache modelCache)
    {
        _dbContext = dbContext;
        _authenticatedUser = authenticatedUser;
        _modelCache = modelCache;
    }

    public async Task<List<RecommendationResponse>> GetAsync()
    {
        var userId = _authenticatedUser.GetUserId()
            ?? throw new UnauthorizedAccessException("No authenticated user in the current request.");

        var rentedVehicleIds = await _dbContext.Reservations
            .Where(x => x.UserId == userId && RecommendationRules.RentalStatuses.Contains(x.Status))
            .Select(x => x.VehicleId)
            .Distinct()
            .ToListAsync();

        var vehicles = await _dbContext.Vehicles
            .Where(x => x.IsActive || rentedVehicleIds.Contains(x.Id))
            .Select(x => new RecommendationVehicle(
                x.Id,
                x.VehicleModel.Brand.Name,
                x.VehicleModel.Name,
                x.CategoryId,
                x.Category.Name,
                x.FuelTypeId,
                x.TransmissionTypeId,
                x.PricePerDay,
                x.Image != null,
                x.IsActive))
            .ToListAsync();

        var candidates = vehicles.Where(x => x.IsActive && !rentedVehicleIds.Contains(x.Id)).ToList();
        var rentedVehicles = vehicles.Where(x => rentedVehicleIds.Contains(x.Id)).ToList();

        var recommendations = rentedVehicles.Count == 0
            ? await GetPopularAsync(candidates)
            : GetPersonalized(candidates, rentedVehicles);

        return recommendations
            .OrderByDescending(x => x.Score)
            .ThenBy(x => x.Vehicle.Id)
            .Take(RecommendationRules.RecommendationCount)
            .Select(x => new RecommendationResponse
            {
                VehicleId = x.Vehicle.Id,
                BrandName = x.Vehicle.BrandName,
                VehicleModelName = x.Vehicle.VehicleModelName,
                CategoryName = x.Vehicle.CategoryName,
                PricePerDay = x.Vehicle.PricePerDay,
                HasImage = x.Vehicle.HasImage,
                Type = x.Type,
                Explanation = x.Explanation
            })
            .ToList();
    }

    private async Task<List<ScoredVehicle>> GetPopularAsync(List<RecommendationVehicle> candidates)
    {
        var rentalCounts = await _dbContext.Reservations
            .Where(x => RecommendationRules.RentalStatuses.Contains(x.Status))
            .GroupBy(x => x.VehicleId)
            .Select(g => new { VehicleId = g.Key, Count = g.Count() })
            .ToDictionaryAsync(x => x.VehicleId, x => x.Count);

        return candidates
            .Where(x => rentalCounts.ContainsKey(x.Id))
            .Select(x => new ScoredVehicle(x, rentalCounts[x.Id], RecommendationType.Popular, RecommendationExplanations.Popular))
            .ToList();
    }

    private List<ScoredVehicle> GetPersonalized(List<RecommendationVehicle> candidates, List<RecommendationVehicle> rentedVehicles)
    {
        var scores = _modelCache.Scores;

        return candidates
            .Select(candidate => ScoreWithModel(scores, candidate, rentedVehicles) ?? ScoreBySimilarity(candidate, rentedVehicles))
            .ToList();
    }

    private static ScoredVehicle? ScoreWithModel(RecommendationScores? scores, RecommendationVehicle candidate,
        List<RecommendationVehicle> rentedVehicles)
    {
        if (scores == null || !scores.Contains(candidate.Id))
        {
            return null;
        }

        var best = rentedVehicles
            .Select(rented => (Rented: rented, Score: scores.GetScore(rented.Id, candidate.Id)))
            .Where(x => x.Score.HasValue)
            .OrderByDescending(x => x.Score)
            .ThenBy(x => x.Rented.Id)
            .FirstOrDefault();

        return best.Score.HasValue
            ? new ScoredVehicle(candidate, best.Score.Value, RecommendationType.Collaborative,
                RecommendationExplanations.Collaborative(best.Rented.Name))
            : null;
    }

    private static ScoredVehicle ScoreBySimilarity(RecommendationVehicle candidate, List<RecommendationVehicle> rentedVehicles)
    {
        var best = rentedVehicles
            .Select(rented => (Rented: rented, Score: VehicleSimilarity.Calculate(rented, candidate)))
            .OrderByDescending(x => x.Score)
            .ThenBy(x => x.Rented.Id)
            .First();

        return new ScoredVehicle(candidate, best.Score, RecommendationType.ContentBased,
            RecommendationExplanations.ContentBased(best.Rented.Name));
    }

    private record ScoredVehicle(RecommendationVehicle Vehicle, double Score, RecommendationType Type, string Explanation);
}
