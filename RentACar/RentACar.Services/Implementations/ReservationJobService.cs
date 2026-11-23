using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using RentACar.Model.Enums;
using RentACar.Model.Exceptions;
using RentACar.Services.Database;
using RentACar.Services.Helpers;
using RentACar.Services.Interfaces;
using RentACar.Services.ReservationStateMachine;

namespace RentACar.Services.Implementations;

public class ReservationJobService : IReservationJobService
{
    private const int BatchSize = 50;

    private readonly RentACarDbContext _dbContext;
    private readonly BaseReservationState _reservationState;
    private readonly PendingEmails _pendingEmails;
    private readonly ILogger<ReservationJobService> _logger;

    public ReservationJobService(RentACarDbContext dbContext, BaseReservationState reservationState, PendingEmails pendingEmails,
        ILogger<ReservationJobService> logger)
    {
        _dbContext = dbContext;
        _reservationState = reservationState;
        _pendingEmails = pendingEmails;
        _logger = logger;
    }

    public async Task<int> ExpireUnpaidReservationsAsync(CancellationToken cancellationToken)
    {
        var createdBefore = DateTime.UtcNow.AddMinutes(-PaymentRules.PaymentDeadlineMinutes);

        var ids = await _dbContext.Reservations
            .AsNoTracking()
            .Where(x => x.Status == ReservationStatus.Pending
                        && x.CreatedAt <= createdBefore
                        && !x.Payments.Any(p => p.Status == PaymentStatus.Paid))
            .OrderBy(x => x.CreatedAt)
            .Select(x => x.Id)
            .Take(BatchSize)
            .ToListAsync(cancellationToken);

        var expired = 0;

        foreach (var id in ids)
        {
            cancellationToken.ThrowIfCancellationRequested();

            try
            {
                if (await ExpireAsync(id))
                {
                    expired++;
                }
            }
            catch (ClientException ex)
            {
                _logger.LogWarning("Unpaid reservation {ReservationId} was not cancelled yet: {Message}", id, ex.Message);
            }
            catch (Exception ex) when (ex is not OperationCanceledException)
            {
                _logger.LogError(ex, "Failed to cancel unpaid reservation {ReservationId}.", id);
            }
            finally
            {
                _pendingEmails.Clear();
                _dbContext.ChangeTracker.Clear();
            }
        }

        return expired;
    }

    public async Task<int> SendPickupRemindersAsync(CancellationToken cancellationToken)
    {
        var now = DateTime.UtcNow;
        var pickupBefore = now.AddHours(ReservationRules.PickupReminderHours);

        var reservations = await _dbContext.Reservations
            .AsNoTracking()
            .Where(x => x.Status == ReservationStatus.Confirmed
                        && x.ReminderSentAt == null
                        && x.PickupAt > now
                        && x.PickupAt <= pickupBefore)
            .OrderBy(x => x.PickupAt)
            .Take(BatchSize)
            .Select(x => new
            {
                Reservation = x,
                VehicleName = x.Vehicle.VehicleModel.Brand.Name + " " + x.Vehicle.VehicleModel.Name
            })
            .ToListAsync(cancellationToken);

        var sent = 0;

        foreach (var item in reservations)
        {
            cancellationToken.ThrowIfCancellationRequested();

            try
            {
                await using var transaction = await _dbContext.Database.BeginTransactionAsync(cancellationToken);

                var updated = await _dbContext.Reservations
                    .Where(x => x.Id == item.Reservation.Id && x.Status == ReservationStatus.Confirmed && x.ReminderSentAt == null)
                    .ExecuteUpdateAsync(s => s.SetProperty(x => x.ReminderSentAt, DateTime.UtcNow), cancellationToken);

                if (updated == 1)
                {
                    _dbContext.Notifications.Add(ReservationNotifications.PickupReminder(item.Reservation, item.VehicleName));
                    await _dbContext.SaveChangesAsync(cancellationToken);
                    sent++;
                }

                await transaction.CommitAsync(cancellationToken);
            }
            catch (Exception ex) when (ex is not OperationCanceledException)
            {
                _logger.LogError(ex, "Failed to send pickup reminder for reservation {ReservationId}.", item.Reservation.Id);
            }
            finally
            {
                _dbContext.ChangeTracker.Clear();
            }
        }

        return sent;
    }

    private async Task<bool> ExpireAsync(int id)
    {
        await using var transaction = await _dbContext.Database.BeginTransactionAsync();

        var reservation = await _dbContext.Reservations
            .FromSql($"SELECT * FROM Reservations WITH (UPDLOCK, ROWLOCK) WHERE Id = {id}")
            .Where(x => x.Id == id)
            .FirstOrDefaultAsync();

        if (reservation == null)
        {
            return false;
        }

        var expired = await _reservationState.GetReservationState(reservation.Status).ExpireAsync(reservation);

        await _dbContext.SaveChangesAsync();
        await transaction.CommitAsync();

        await _pendingEmails.PublishAsync();

        if (expired)
        {
            _logger.LogInformation("Reservation {ReservationId} cancelled: not paid within {Minutes} minutes.",
                id, PaymentRules.PaymentDeadlineMinutes);
        }

        return expired;
    }
}
