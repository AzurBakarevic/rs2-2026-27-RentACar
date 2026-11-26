namespace RentACar.Services.Recommendations;

public class RecommendationScores
{
    private readonly IReadOnlyDictionary<(int VehicleId, int CandidateVehicleId), float> _scores;
    private readonly HashSet<int> _vehicleIds;

    public RecommendationScores(string dataHash, IReadOnlyDictionary<(int VehicleId, int CandidateVehicleId), float> scores)
    {
        DataHash = dataHash;
        _scores = scores;
        _vehicleIds = scores.Keys.Select(x => x.VehicleId).ToHashSet();
    }

    public string DataHash { get; }

    public bool Contains(int vehicleId) => _vehicleIds.Contains(vehicleId);

    public float? GetScore(int vehicleId, int candidateVehicleId) =>
        _scores.TryGetValue((vehicleId, candidateVehicleId), out var score) ? score : null;

    public static RecommendationScores Empty(string dataHash) =>
        new(dataHash, new Dictionary<(int VehicleId, int CandidateVehicleId), float>());
}
