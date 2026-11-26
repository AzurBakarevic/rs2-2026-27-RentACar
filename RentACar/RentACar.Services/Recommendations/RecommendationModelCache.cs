namespace RentACar.Services.Recommendations;

public class RecommendationModelCache
{
    private volatile RecommendationScores? _scores;

    public RecommendationScores? Scores => _scores;

    public void Set(RecommendationScores scores)
    {
        _scores = scores;
    }
}
