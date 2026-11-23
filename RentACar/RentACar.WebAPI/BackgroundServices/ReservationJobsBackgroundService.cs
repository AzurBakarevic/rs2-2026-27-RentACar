using RentACar.Services.Interfaces;

namespace RentACar.WebAPI.BackgroundServices;

public class ReservationJobsBackgroundService : BackgroundService
{
    private static readonly TimeSpan Interval = TimeSpan.FromMinutes(1);

    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<ReservationJobsBackgroundService> _logger;

    public ReservationJobsBackgroundService(IServiceScopeFactory scopeFactory, ILogger<ReservationJobsBackgroundService> logger)
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
            var jobs = scope.ServiceProvider.GetRequiredService<IReservationJobService>();

            var expired = await jobs.ExpireUnpaidReservationsAsync(stoppingToken);
            var reminders = await jobs.SendPickupRemindersAsync(stoppingToken);

            if (expired > 0 || reminders > 0)
            {
                _logger.LogInformation("Reservation jobs: {Expired} unpaid reservations cancelled, {Reminders} pickup reminders sent.",
                    expired, reminders);
            }
        }
        catch (Exception ex) when (!stoppingToken.IsCancellationRequested)
        {
            _logger.LogError(ex, "Reservation jobs failed; retrying in {Interval}.", Interval);
        }
    }
}
