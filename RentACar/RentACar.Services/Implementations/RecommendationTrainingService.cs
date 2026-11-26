using System.Security.Cryptography;
using System.Text;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using RentACar.Services.Database;
using RentACar.Services.Interfaces;
using RentACar.Services.Recommendations;

namespace RentACar.Services.Implementations;

public class RecommendationTrainingService : IRecommendationTrainingService
{
    private readonly RentACarDbContext _dbContext;
    private readonly RecommendationModelCache _modelCache;
    private readonly ILogger<RecommendationTrainingService> _logger;

    public RecommendationTrainingService(RentACarDbContext dbContext, RecommendationModelCache modelCache,
        ILogger<RecommendationTrainingService> logger)
    {
        _dbContext = dbContext;
        _modelCache = modelCache;
        _logger = logger;
    }

    public async Task UpdateModelAsync(CancellationToken cancellationToken)
    {
        var rentals = await _dbContext.Reservations
            .AsNoTracking()
            .Where(x => RecommendationRules.RentalStatuses.Contains(x.Status))
            .Select(x => new { x.UserId, x.VehicleId })
            .Distinct()
            .ToListAsync(cancellationToken);

        var customerRentals = rentals
            .Select(x => new CustomerRental(x.UserId, x.VehicleId))
            .OrderBy(x => x.UserId)
            .ThenBy(x => x.VehicleId)
            .ToList();
        var dataHash = ComputeHash(customerRentals);

        if (_modelCache.Scores?.DataHash == dataHash)
        {
            return;
        }

        var pairs = CreateTrainingPairs(customerRentals);

        if (pairs.Count == 0)
        {
            _modelCache.Set(RecommendationScores.Empty(dataHash));
            _logger.LogInformation("Recommendation model was not trained: no customer has rented more than one vehicle.");
            return;
        }

        var savedModel = await _dbContext.RecommendationModels
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.DataHash == dataHash, cancellationToken);

        var vehicleIds = pairs.Select(x => x.VehicleId).Distinct().ToList();
        byte[] modelData;

        if (savedModel != null)
        {
            modelData = savedModel.Data;
            _logger.LogInformation("Loaded saved recommendation model trained at {TrainedAt}.", savedModel.TrainedAt);
        }
        else
        {
            modelData = RecommendationModelTrainer.Train(pairs);
            await SaveModelAsync(modelData, dataHash, cancellationToken);
            _logger.LogInformation("Trained recommendation model on {PairCount} pairs of {VehicleCount} vehicles.",
                pairs.Count, vehicleIds.Count);
        }

        _modelCache.Set(new RecommendationScores(dataHash, RecommendationModelTrainer.PredictScores(modelData, vehicleIds)));
    }

    private static List<VehicleRentalPair> CreateTrainingPairs(List<CustomerRental> rentals)
    {
        var customerCounts = rentals
            .GroupBy(x => x.VehicleId)
            .ToDictionary(g => g.Key, g => g.Count());

        var sharedCustomerCounts = rentals
            .GroupBy(x => x.UserId)
            .SelectMany(customer => customer.SelectMany(rented => customer
                .Where(other => other.VehicleId != rented.VehicleId)
                .Select(other => (VehicleId: rented.VehicleId, CoRentedVehicleId: other.VehicleId))))
            .GroupBy(x => x)
            .ToDictionary(g => g.Key, g => g.Count());

        var vehicleIds = sharedCustomerCounts.Keys
            .Select(x => x.VehicleId)
            .Distinct()
            .Order()
            .ToList();

        return vehicleIds
            .SelectMany(vehicleId => vehicleIds
                .Where(coRentedVehicleId => coRentedVehicleId != vehicleId)
                .Select(coRentedVehicleId => new VehicleRentalPair
                {
                    VehicleId = vehicleId,
                    CoRentedVehicleId = coRentedVehicleId,
                    Label = (float)sharedCustomerCounts.GetValueOrDefault((vehicleId, coRentedVehicleId)) / customerCounts[vehicleId]
                }))
            .ToList();
    }

    private async Task SaveModelAsync(byte[] modelData, string dataHash, CancellationToken cancellationToken)
    {
        await using var transaction = await _dbContext.Database.BeginTransactionAsync(cancellationToken);

        await _dbContext.RecommendationModels.ExecuteDeleteAsync(cancellationToken);
        _dbContext.RecommendationModels.Add(new RecommendationModel
        {
            Data = modelData,
            DataHash = dataHash,
            TrainedAt = DateTime.UtcNow
        });
        await _dbContext.SaveChangesAsync(cancellationToken);

        await transaction.CommitAsync(cancellationToken);
    }

    private static string ComputeHash(List<CustomerRental> rentals)
    {
        var text = string.Join(';', rentals.Select(x => $"{x.UserId}-{x.VehicleId}"));
        return Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(text)));
    }

    private record CustomerRental(int UserId, int VehicleId);
}
