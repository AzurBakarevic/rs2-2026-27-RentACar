using Microsoft.ML;
using Microsoft.ML.Trainers;

namespace RentACar.Services.Recommendations;

public static class RecommendationModelTrainer
{
    private const int Seed = 0;
    private const string VehicleKeyColumn = "VehicleKey";
    private const string CoRentedVehicleKeyColumn = "CoRentedVehicleKey";
    private const double Lambda = 0.025;
    private const int NumberOfIterations = 100;
    private const int NumberOfThreads = 1;

    public static byte[] Train(IReadOnlyCollection<VehicleRentalPair> pairs)
    {
        var mlContext = new MLContext(Seed);
        var data = mlContext.Data.LoadFromEnumerable(pairs);

        var pipeline = mlContext.Transforms.Conversion.MapValueToKey(VehicleKeyColumn, nameof(VehicleRentalPair.VehicleId))
            .Append(mlContext.Transforms.Conversion.MapValueToKey(CoRentedVehicleKeyColumn, nameof(VehicleRentalPair.CoRentedVehicleId)))
            .Append(mlContext.Recommendation().Trainers.MatrixFactorization(new MatrixFactorizationTrainer.Options
            {
                MatrixColumnIndexColumnName = VehicleKeyColumn,
                MatrixRowIndexColumnName = CoRentedVehicleKeyColumn,
                LabelColumnName = nameof(VehicleRentalPair.Label),
                LossFunction = MatrixFactorizationTrainer.LossFunctionType.SquareLossRegression,
                Lambda = Lambda,
                NumberOfIterations = NumberOfIterations,
                NumberOfThreads = NumberOfThreads,
                Quiet = true
            }));

        var model = pipeline.Fit(data);

        using var stream = new MemoryStream();
        mlContext.Model.Save(model, data.Schema, stream);
        return stream.ToArray();
    }

    public static Dictionary<(int VehicleId, int CandidateVehicleId), float> PredictScores(byte[] modelData,
        IReadOnlyCollection<int> vehicleIds)
    {
        var mlContext = new MLContext(Seed);

        using var stream = new MemoryStream(modelData);
        var model = mlContext.Model.Load(stream, out _);
        using var engine = mlContext.Model.CreatePredictionEngine<VehicleRentalPair, VehiclePairPrediction>(model);

        var scores = new Dictionary<(int VehicleId, int CandidateVehicleId), float>();

        foreach (var vehicleId in vehicleIds)
        {
            foreach (var candidateVehicleId in vehicleIds.Where(x => x != vehicleId))
            {
                var prediction = engine.Predict(new VehicleRentalPair { VehicleId = vehicleId, CoRentedVehicleId = candidateVehicleId });

                if (float.IsFinite(prediction.Score))
                {
                    scores[(vehicleId, candidateVehicleId)] = Math.Clamp(prediction.Score, 0f, 1f);
                }
            }
        }

        return scores;
    }
}
