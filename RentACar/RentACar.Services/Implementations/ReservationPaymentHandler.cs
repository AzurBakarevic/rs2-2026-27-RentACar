using System.Globalization;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using RentACar.Model.Enums;
using RentACar.Model.Exceptions;
using RentACar.Services.Database;
using RentACar.Services.Helpers;
using RentACar.Services.Interfaces;

namespace RentACar.Services.Implementations;

public class ReservationPaymentHandler
{
    public const string ReservationIdKey = "reservation_id";
    public const string UserIdKey = "user_id";

    private readonly RentACarDbContext _dbContext;
    private readonly IPaymentGateway _gateway;
    private readonly ILogger<ReservationPaymentHandler> _logger;

    public ReservationPaymentHandler(RentACarDbContext dbContext, IPaymentGateway gateway, ILogger<ReservationPaymentHandler> logger)
    {
        _dbContext = dbContext;
        _gateway = gateway;
        _logger = logger;
    }

    public Task<Payment?> GetActivePaymentAsync(int reservationId)
        => _dbContext.Payments.FirstOrDefaultAsync(x => x.ReservationId == reservationId && x.Status != PaymentStatus.Cancelled);

    public async Task<Payment?> SyncAsync(Reservation reservation)
    {
        var payment = await GetActivePaymentAsync(reservation.Id);
        if (payment is not { Status: PaymentStatus.Pending })
        {
            return payment;
        }

        var intent = await _gateway.GetPaymentIntentAsync(payment.StripePaymentIntentId);
        return await ApplyAsync(reservation, payment, intent);
    }

    public async Task<Payment?> ApplyAsync(Reservation reservation, Payment payment, GatewayPaymentIntent intent)
    {
        if (intent.IsSucceeded)
        {
            await MarkPaidAsync(reservation, payment, intent);
        }
        else if (intent.IsCanceled)
        {
            payment.Status = PaymentStatus.Cancelled;
            return null;
        }

        return payment;
    }

    public async Task ReleaseAsync(Reservation reservation)
    {
        var payment = await GetActivePaymentAsync(reservation.Id);
        if (payment == null)
        {
            return;
        }

        if (payment.Status == PaymentStatus.Pending)
        {
            var intent = await _gateway.CancelPaymentIntentAsync(payment.StripePaymentIntentId);

            if (intent.IsCanceled)
            {
                payment.Status = PaymentStatus.Cancelled;
                return;
            }

            if (!intent.IsSucceeded)
            {
                throw new ClientException("Plaćanje se još obrađuje, pa rezervaciju trenutno nije moguće otkazati. " +
                                          "Pokušajte ponovo za nekoliko minuta.");
            }

            await MarkPaidAsync(reservation, payment, intent);
        }

        if (payment.Status == PaymentStatus.Paid)
        {
            await RefundAsync(reservation, payment);
        }
    }

    public static Dictionary<string, string> CreateMetadata(Reservation reservation) => new()
    {
        [ReservationIdKey] = reservation.Id.ToString(CultureInfo.InvariantCulture),
        [UserIdKey] = reservation.UserId.ToString(CultureInfo.InvariantCulture)
    };

    private async Task MarkPaidAsync(Reservation reservation, Payment payment, GatewayPaymentIntent intent)
    {
        EnsureBelongsToReservation(reservation, payment, intent);

        payment.Status = PaymentStatus.Paid;
        payment.PaidAt = DateTime.UtcNow;
        payment.ChargedAmount = PaymentRules.FromMinorUnits(intent.AmountReceived);

        _dbContext.Notifications.Add(ReservationNotifications.Paid(reservation, await GetVehicleNameAsync(reservation),
            payment.ChargedAmount.Value));

        _logger.LogInformation("Reservation {ReservationId} paid (payment intent {PaymentIntentId}).",
            reservation.Id, payment.StripePaymentIntentId);
    }

    private async Task RefundAsync(Reservation reservation, Payment payment)
    {
        var refund = await _gateway.RefundAsync(payment.StripePaymentIntentId, $"refund-payment-{payment.Id}",
            CreateMetadata(reservation));

        if (refund.Status is not ("succeeded" or "pending"))
        {
            _logger.LogError("Refund {RefundId} for reservation {ReservationId} has status {Status}.", refund.Id, reservation.Id, refund.Status);
            throw new PaymentGatewayException("Povrat novca nije uspio, pa promjena nije spremljena. Pokušajte ponovo za nekoliko minuta.");
        }

        payment.Status = PaymentStatus.Refunded;
        payment.RefundedAt = DateTime.UtcNow;
        payment.StripeRefundId = refund.Id;

        _dbContext.Notifications.Add(ReservationNotifications.Refunded(reservation, await GetVehicleNameAsync(reservation),
            PaymentRules.FromMinorUnits(refund.Amount)));

        _logger.LogInformation("Reservation {ReservationId} refunded (refund {RefundId}, status {Status}).",
            reservation.Id, refund.Id, refund.Status);
    }

    private void EnsureBelongsToReservation(Reservation reservation, Payment payment, GatewayPaymentIntent intent)
    {
        var expectedAmount = PaymentRules.ToMinorUnits(payment.Amount);
        var belongs = intent.Id == payment.StripePaymentIntentId
                      && intent.Currency == PaymentRules.Currency
                      && intent.Amount == expectedAmount
                      && intent.AmountReceived == expectedAmount
                      && intent.Metadata.TryGetValue(ReservationIdKey, out var reservationId)
                      && reservationId == reservation.Id.ToString(CultureInfo.InvariantCulture);

        if (!belongs)
        {
            _logger.LogError("Payment intent {PaymentIntentId} does not match reservation {ReservationId} " +
                             "(amount {Amount}/{AmountReceived} {Currency}, expected {Expected}).",
                intent.Id, reservation.Id, intent.Amount, intent.AmountReceived, intent.Currency, expectedAmount);
            throw new ClientException("Uplata ne odgovara ovoj rezervaciji. Obratite se agenciji.");
        }
    }

    private Task<string> GetVehicleNameAsync(Reservation reservation)
        => _dbContext.Vehicles
            .Where(x => x.Id == reservation.VehicleId)
            .Select(x => x.VehicleModel.Brand.Name + " " + x.VehicleModel.Name)
            .FirstAsync();
}
