using RentACar.Services.Interfaces;

namespace RentACar.WebAPI.BackgroundServices;

public class RecommendationTrainingBackgroundService : BackgroundService
{
    private static readonly TimeSpan Interval = TimeSpan.FromMinutes(5);

    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<RecommendationTrainingBackgroundService> _logger;

    public RecommendationTrainingBackgroundService(IServiceScopeFactory scopeFactory,
        ILogger<RecommendationTrainingBackgroundService> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        using var timer = new PeriodicTimer(Interval);

        do
        {
            await RunOnceAsync(stoppingToken);
        }
        while (await timer.WaitForNextTickAsync(stoppingToken));
    }

    private async Task RunOnceAsync(CancellationToken stoppingToken)
    {
        try
        {
            await using var scope = _scopeFactory.CreateAsyncScope();
            var training = scope.ServiceProvider.GetRequiredService<IRecommendationTrainingService>();

            await training.UpdateModelAsync(stoppingToken);
        }
        catch (Exception ex) when (!stoppingToken.IsCancellationRequested)
        {
            _logger.LogError(ex, "Recommendation model update failed; retrying in {Interval}.", Interval);
        }
    }
}
