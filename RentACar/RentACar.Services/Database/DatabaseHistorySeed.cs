using Microsoft.EntityFrameworkCore;
using RentACar.Model.Enums;
using RentACar.Services.Helpers;

namespace RentACar.Services.Database;

public static class DatabaseHistorySeed
{
    private const int AdministratorId = 1;
    private const int MobileCustomerId = 2;
    private const int UnreviewedMobileReservations = 2;

    private const int HistoryDays = 365;
    private const int RecentPickupDays = 12;
    private const int InactiveVehicleLastRentalDays = 100;
    private const int InactiveCustomerLastRentalDays = 60;
    private const int ReadAfterDays = 7;

    private const int FutureMaintenanceVehicleId = 2;
    private const int FutureMaintenanceInDays = 6;

    private const int ChildSeatId = 1;
    private const int NavigationId = 2;
    private const int RoofRackId = 3;
    private const int SnowChainsId = 4;

    private static readonly int[] CityVehicleIds = [4, 6, 8, 10];
    private static readonly int[] FamilyVehicleIds = [1, 2, 7];
    private static readonly int[] SuvVehicleIds = [3, 5];
    private static readonly int[] RoofRackVehicleIds = [3, 5, 7];

    private static readonly int[] CityCustomerIds = [5, 7, 9, 12];
    private static readonly int[] FamilyCustomerIds = [2, 4, 10, 13];
    private static readonly int[] SuvCustomerIds = [3, 6, 11];
    private static readonly int[] AllCustomerIds = [.. CityCustomerIds, .. FamilyCustomerIds, .. SuvCustomerIds];

    private static readonly int[] RentalLengths = [3, 2, 5, 1, 4, 7, 2, 3, 6, 2, 4, 3];
    private static readonly int[] Gaps = [8, 12, 6, 15, 10, 20, 7, 14, 9, 22, 8, 13];
    private static readonly int[] LeadDays = [2, 5, 1, 9, 3, 14, 4, 7, 2, 10, 6, 3];
    private static readonly int[] PickupHours = [9, 10, 8, 11, 14, 9, 12, 10];
    private static readonly int[] ConfirmDelayMinutes = [40, 180, 25, 360, 90, 15, 240];
    private static readonly int[] RatingOffsets = [0, 0, -1, 0, 1, -2, 0, -1, 0, 0, -3, 0];

    private static readonly Dictionary<int, int> BaseRatings = new()
    {
        [1] = 5, [2] = 4, [3] = 5, [4] = 3, [5] = 4, [6] = 4, [7] = 5, [8] = 4, [10] = 4
    };

    private static readonly string[][] Comments =
    [
        [
            "Loše iskustvo: vozilo je bilo prljavo, a gume istrošene.",
            "Vozilo je u toku najma imalo upaljenu lampicu za kvar motora."
        ],
        [
            "Preuzimanje je kasnilo skoro sat vremena.",
            "Klima nije radila, a u opisu je navedena."
        ],
        [
            "Vozilo je bilo u redu, ali unutrašnjost nije bila očišćena.",
            "Prosječno iskustvo, potrošnja veća nego što je navedeno."
        ],
        [
            "Dobro vozilo, jedino je rezervoar pri preuzimanju bio poluprazan.",
            "Sve uredu, preuzimanje je malo kasnilo.",
            "Udobno i pouzdano, nemam šta posebno zamjeriti."
        ],
        [
            "Odlično vozilo, čisto i uredno. Preuzimanje je trajalo pet minuta.",
            "Sve je bilo kako treba, rado ću ponovo iznajmiti.",
            "Vrlo udobno za duži put, a potrošnja je mala.",
            "Vozilo kao novo, preporuka."
        ]
    ];

    private static readonly string[] RejectReasons =
    [
        "Vozilo u tom periodu nije dostupno zbog neplaniranog servisa.",
        "Podaci o vozačkoj dozvoli se ne poklapaju s dokumentom.",
        "Traženo vrijeme preuzimanja je izvan radnog vremena poslovnice."
    ];

    private static readonly string?[] CustomerCancelReasons = [null, "Promjena plana putovanja.", null, "Pronađen drugi prevoz."];

    private const string CancelBeforePickupReason = "Kvar vozila prije preuzimanja.";
    private const string CancelDuringRentalReason = "Kvar vozila u toku najma.";

    private static readonly (string Description, decimal Cost)[] RegularMaintenances =
    [
        ("Redovni servis: zamjena ulja i filtera", 185m),
        ("Tehnički pregled i produženje registracije", 260m),
        ("Zamjena kočionih pločica i diskova", 340m),
        ("Servis klima uređaja", 120m)
    ];

    private static readonly (int DaysAgo, int CustomerId, int VehicleId, int PickupInDays, int RentalDays, Outcome Outcome)[] RecentReservations =
    [
        (1, 5, 8, 5, 3, Outcome.Expired),
        (2, 3, 3, 12, 4, Outcome.CancelledByCustomer),
        (4, 10, 1, 3, 2, Outcome.Expired),
        (5, 9, 6, 9, 3, Outcome.Rejected),
        (6, 2, 7, 15, 5, Outcome.CancelledByCustomer)
    ];

    private enum Outcome
    {
        Completed,
        CancelledByCustomer,
        Rejected,
        CancelledByAdministrator,
        Expired
    }

    private sealed record SeedVehicle(int Id, string Name, decimal PricePerDay, bool IsActive);

    private sealed record Slot(SeedVehicle Vehicle, DateTime PickupAt, DateTime ReturnAt);

    private sealed record EquipmentBooking(int EquipmentId, int Quantity, DateTime From, DateTime To);

    public static async Task<int> SeedReservationHistoryAsync(this RentACarDbContext dbContext)
    {
        if (await dbContext.Reservations.AnyAsync())
        {
            return 0;
        }

        var customers = await dbContext.Users
            .AsNoTracking()
            .Where(x => AllCustomerIds.Contains(x.Id) && !x.IsDeleted)
            .ToDictionaryAsync(x => x.Id, x => x.IsActive);

        var vehicles = await dbContext.Vehicles
            .AsNoTracking()
            .Select(x => new SeedVehicle(x.Id, x.VehicleModel.Brand.Name + " " + x.VehicleModel.Name, x.PricePerDay, x.IsActive))
            .ToListAsync();

        var equipment = await dbContext.Equipment
            .AsNoTracking()
            .Where(x => x.IsActive)
            .ToDictionaryAsync(x => x.Id);

        var seasons = await dbContext.SeasonalPrices
            .AsNoTracking()
            .Where(x => x.IsActive)
            .ToListAsync();

        var generator = new HistoryGenerator(DateTime.UtcNow, customers, vehicles, equipment, seasons);
        generator.Generate();

        dbContext.Reservations.AddRange(generator.Reservations);
        dbContext.Notifications.AddRange(generator.Notifications);
        dbContext.VehicleMaintenances.AddRange(generator.Maintenances);
        await dbContext.SaveChangesAsync();

        return generator.Reservations.Count;
    }

    private static T Cycle<T>(T[] values, int index) => values[index % values.Length];

    private static int[] CustomerGroupFor(int vehicleId)
        => CityVehicleIds.Contains(vehicleId) ? CityCustomerIds
            : FamilyVehicleIds.Contains(vehicleId) ? FamilyCustomerIds
            : SuvCustomerIds;

    private static bool IsRented(int vehicleId)
        => CityVehicleIds.Contains(vehicleId) || FamilyVehicleIds.Contains(vehicleId) || SuvVehicleIds.Contains(vehicleId);

    private static Outcome OutcomeFor(int index)
        => index % 9 == 4 ? Outcome.CancelledByCustomer
            : index % 13 == 7 ? Outcome.Rejected
            : index % 29 == 18 ? Outcome.CancelledByAdministrator
            : index % 17 == 10 ? Outcome.Expired
            : Outcome.Completed;

    private sealed class HistoryGenerator
    {
        private readonly DateTime _now;
        private readonly DateOnly _today;
        private readonly Dictionary<int, bool> _customers;
        private readonly List<SeedVehicle> _vehicles;
        private readonly Dictionary<int, Equipment> _equipment;
        private readonly List<SeasonalPrice> _seasons;
        private readonly Dictionary<int, List<(DateTime From, DateTime To)>> _customerRentals = [];
        private readonly List<EquipmentBooking> _equipmentBookings = [];
        private int _paymentNumber;

        public HistoryGenerator(DateTime now, Dictionary<int, bool> customers, List<SeedVehicle> vehicles,
            Dictionary<int, Equipment> equipment, List<SeasonalPrice> seasons)
        {
            _now = now;
            _today = AgencyTime.ToLocalDate(now);
            _customers = customers;
            _vehicles = vehicles;
            _equipment = equipment;
            _seasons = seasons;
        }

        public List<Reservation> Reservations { get; } = [];
        public List<Notification> Notifications { get; } = [];
        public List<VehicleMaintenance> Maintenances { get; } = [];

        public void Generate()
        {
            var slots = CreateSlots();
            AddMaintenances(slots);

            var index = 0;
            foreach (var slot in slots.OrderBy(x => x.PickupAt).ThenBy(x => x.Vehicle.Id))
            {
                var customerId = PickCustomer(slot, index);
                if (customerId.HasValue)
                {
                    AddReservation(slot, customerId.Value, index);
                }

                index++;
            }

            AddRecentReservations();
            LeaveMobileReservationsUnreviewed();
        }

        private List<Slot> CreateSlots()
        {
            var slots = new List<Slot>();
            var firstDay = _today.AddDays(-HistoryDays);
            var position = 0;

            foreach (var vehicle in _vehicles.Where(x => IsRented(x.Id)).OrderBy(x => x.Id))
            {
                var lastReturnDay = vehicle.IsActive ? _today.AddDays(-1) : _today.AddDays(-InactiveVehicleLastRentalDays);
                var day = firstDay.AddDays(position * 2);

                for (var k = 0; ; k++)
                {
                    var pickupDay = day.AddDays(Cycle(Gaps, k + position));
                    var returnDay = pickupDay.AddDays(Cycle(RentalLengths, k * 3 + position));
                    if (returnDay > lastReturnDay)
                    {
                        break;
                    }

                    var hour = Cycle(PickupHours, k + position);
                    var lateReturnHours = (k + position) % 7 == 3 ? 2 : 0;

                    slots.Add(new Slot(vehicle,
                        AgencyTime.StartOfDayUtc(pickupDay).AddHours(hour),
                        AgencyTime.StartOfDayUtc(returnDay).AddHours(hour + lateReturnHours)));

                    day = returnDay;
                }

                position++;
            }

            return slots;
        }

        private void AddMaintenances(List<Slot> slots)
        {
            var number = 0;

            foreach (var vehicleSlots in slots.GroupBy(x => x.Vehicle.Id))
            {
                var ordered = vehicleSlots.OrderBy(x => x.PickupAt).ToList();

                for (var i = 1; i < ordered.Count; i++)
                {
                    var previousReturnDay = AgencyTime.ToLocalDate(ordered[i - 1].ReturnAt);
                    var nextPickupDay = AgencyTime.ToLocalDate(ordered[i].PickupAt);

                    if (i % 5 == 2 && nextPickupDay.DayNumber - previousReturnDay.DayNumber >= 4)
                    {
                        var startDay = previousReturnDay.AddDays(1);
                        var (description, cost) = MaintenanceFor(startDay, number++);
                        AddMaintenance(vehicleSlots.Key, startDay, startDay, description, cost);
                    }
                }

                var vehicle = ordered[0].Vehicle;
                if (!vehicle.IsActive)
                {
                    var startDay = AgencyTime.ToLocalDate(ordered[^1].ReturnAt).AddDays(2);
                    AddMaintenance(vehicle.Id, startDay, startDay.AddDays(3), "Kvar mjenjača: vozilo povučeno iz ponude do popravka", 1250m);
                }
            }

            if (_vehicles.Any(x => x.Id == FutureMaintenanceVehicleId && x.IsActive))
            {
                var startDay = _today.AddDays(FutureMaintenanceInDays);
                AddMaintenance(FutureMaintenanceVehicleId, startDay, startDay.AddDays(1),
                    "Veliki servis: zamjena zupčastog remena i pumpe za vodu", 480m);
            }
        }

        private static (string Description, decimal Cost) MaintenanceFor(DateOnly day, int number) => day.Month switch
        {
            10 or 11 => ("Zamjena ljetnih guma zimskim", 60m),
            3 or 4 => ("Zamjena zimskih guma ljetnim", 60m),
            _ => Cycle(RegularMaintenances, number)
        };

        private void AddMaintenance(int vehicleId, DateOnly startDay, DateOnly endDay, string description, decimal cost)
        {
            Maintenances.Add(new VehicleMaintenance
            {
                VehicleId = vehicleId,
                StartAt = AgencyTime.StartOfDayUtc(startDay).AddHours(8),
                EndAt = AgencyTime.StartOfDayUtc(endDay).AddHours(16),
                Description = description,
                Cost = cost
            });
        }

        private int? PickCustomer(Slot slot, int index)
        {
            var group = CustomerGroupFor(slot.Vehicle.Id);
            var preferred = index % 5 == 4 ? AllCustomerIds.Except(group) : group;

            return FirstFreeCustomer(preferred, slot) ?? FirstFreeCustomer(AllCustomerIds, slot);
        }

        private int? FirstFreeCustomer(IEnumerable<int> candidates, Slot slot)
            => candidates
                .Where(id => _customers.TryGetValue(id, out var isActive) && CanRent(id, isActive, slot))
                .OrderBy(id => _customerRentals.TryGetValue(id, out var rentals) ? rentals.Count : 0)
                .ThenBy(id => id)
                .Select(id => (int?)id)
                .FirstOrDefault();

        private bool CanRent(int customerId, bool isActive, Slot slot)
        {
            if (!isActive && slot.ReturnAt > _now.AddDays(-InactiveCustomerLastRentalDays))
            {
                return false;
            }

            return !_customerRentals.TryGetValue(customerId, out var rentals)
                   || rentals.All(x => x.To.AddDays(1) <= slot.PickupAt || slot.ReturnAt.AddDays(1) <= x.From);
        }

        private void AddReservation(Slot slot, int customerId, int index)
        {
            var isRecent = AgencyTime.ToLocalDate(slot.PickupAt) >= _today.AddDays(-RecentPickupDays);
            var leadDays = isRecent ? 1 + index % 2 : Cycle(LeadDays, index);
            var createdAt = slot.PickupAt.AddDays(-leadDays).AddHours(-(1 + index % 5));

            var outcome = OutcomeFor(index);
            if (outcome == Outcome.CancelledByCustomer && leadDays < 2)
            {
                outcome = Outcome.Completed;
            }

            var equipment = outcome == Outcome.Expired ? [] : PickEquipment(slot, index);
            var reservation = CreateReservation(slot.Vehicle, customerId, slot.PickupAt, slot.ReturnAt, createdAt, equipment);

            if (!_customerRentals.TryGetValue(customerId, out var rentals))
            {
                rentals = [];
                _customerRentals[customerId] = rentals;
            }

            rentals.Add((slot.PickupAt, slot.ReturnAt));

            var vehicleName = slot.Vehicle.Name;

            if (outcome == Outcome.Expired)
            {
                Expire(reservation, vehicleName, createdAt);
                return;
            }

            var paidAt = Pay(reservation, vehicleName, createdAt.AddMinutes(1));

            if (outcome == Outcome.Rejected)
            {
                Reject(reservation, vehicleName, paidAt.AddHours(2), Cycle(RejectReasons, index));
                return;
            }

            var confirmedAt = Confirm(reservation, vehicleName, ConfirmTime(paidAt, slot.PickupAt, index));

            switch (outcome)
            {
                case Outcome.CancelledByCustomer:
                {
                    var latest = slot.PickupAt.AddHours(-ReservationRules.CustomerCancellationNoticeHours);
                    var cancelledAt = confirmedAt + (latest - confirmedAt) / 2;
                    CancelByCustomer(reservation, vehicleName, cancelledAt, Cycle(CustomerCancelReasons, index));
                    break;
                }
                case Outcome.CancelledByAdministrator:
                {
                    var duringRental = reservation.RentalDays >= 3;
                    var cancelledAt = duringRental
                        ? slot.PickupAt.AddDays(1)
                        : Max(slot.PickupAt.AddHours(-3), confirmedAt.AddMinutes(30));
                    SendReminder(reservation, vehicleName, confirmedAt, cancelledAt);
                    CancelByAdministrator(reservation, vehicleName, cancelledAt,
                        cancelledAt >= slot.PickupAt ? CancelDuringRentalReason : CancelBeforePickupReason);
                    break;
                }
                default:
                {
                    SendReminder(reservation, vehicleName, confirmedAt, null);
                    var completedAt = slot.ReturnAt.AddMinutes(45);
                    ChangeStatus(reservation, ReservationStatus.Completed, completedAt, AdministratorId, null);
                    Notify(ReservationNotifications.Completed(reservation, vehicleName), completedAt);
                    AddReview(reservation, completedAt, index);
                    break;
                }
            }
        }

        private void AddRecentReservations()
        {
            foreach (var item in RecentReservations)
            {
                var vehicle = _vehicles.FirstOrDefault(x => x.Id == item.VehicleId && x.IsActive);
                if (vehicle == null || !_customers.TryGetValue(item.CustomerId, out var isActive) || !isActive)
                {
                    continue;
                }

                var createdAt = _now.AddDays(-item.DaysAgo).AddHours(-2);
                var pickupAt = AgencyTime.StartOfDayUtc(_today.AddDays(item.PickupInDays)).AddHours(10);
                var reservation = CreateReservation(vehicle, item.CustomerId, pickupAt, pickupAt.AddDays(item.RentalDays), createdAt, []);

                if (item.Outcome == Outcome.Expired)
                {
                    Expire(reservation, vehicle.Name, createdAt);
                    continue;
                }

                var paidAt = Pay(reservation, vehicle.Name, createdAt.AddMinutes(1));

                if (item.Outcome == Outcome.Rejected)
                {
                    Reject(reservation, vehicle.Name, paidAt.AddHours(3), RejectReasons[0]);
                    continue;
                }

                if (item.DaysAgo > 3)
                {
                    Confirm(reservation, vehicle.Name, paidAt.AddHours(2));
                }

                CancelByCustomer(reservation, vehicle.Name, createdAt.AddHours(item.DaysAgo * 12), CustomerCancelReasons[1]);
            }
        }

        private void LeaveMobileReservationsUnreviewed()
        {
            var latest = Reservations
                .Where(x => x.UserId == MobileCustomerId && x.Status == ReservationStatus.Completed)
                .OrderByDescending(x => x.ReturnAt)
                .Take(UnreviewedMobileReservations);

            foreach (var reservation in latest)
            {
                reservation.Review = null;
            }
        }

        private List<ReservationEquipment> PickEquipment(Slot slot, int index)
        {
            var requested = new List<(int EquipmentId, int Quantity)>();

            if (index % 4 == 1)
            {
                requested.Add((NavigationId, 1));
            }

            if (FamilyVehicleIds.Contains(slot.Vehicle.Id) && index % 3 == 0)
            {
                requested.Add((ChildSeatId, index % 2 == 0 ? 2 : 1));
            }

            if (RoofRackVehicleIds.Contains(slot.Vehicle.Id) && index % 5 == 2)
            {
                requested.Add((RoofRackId, 1));
            }

            if (AgencyTime.ToLocalDate(slot.PickupAt).Month is 12 or 1 or 2 && index % 2 == 0)
            {
                requested.Add((SnowChainsId, 1));
            }

            var items = new List<ReservationEquipment>();

            foreach (var (equipmentId, quantity) in requested)
            {
                if (!_equipment.TryGetValue(equipmentId, out var piece))
                {
                    continue;
                }

                var booked = _equipmentBookings
                    .Where(x => x.EquipmentId == equipmentId && x.From < slot.ReturnAt && slot.PickupAt < x.To)
                    .Sum(x => x.Quantity);

                if (booked + quantity > piece.Quantity)
                {
                    continue;
                }

                _equipmentBookings.Add(new EquipmentBooking(equipmentId, quantity, slot.PickupAt, slot.ReturnAt));
                items.Add(new ReservationEquipment { EquipmentId = equipmentId, Quantity = quantity, PricePerDay = piece.PricePerDay });
            }

            return items;
        }

        private Reservation CreateReservation(SeedVehicle vehicle, int customerId, DateTime pickupAt, DateTime returnAt,
            DateTime createdAt, List<ReservationEquipment> equipment)
        {
            var rentalDays = ReservationRules.GetRentalDays(pickupAt, returnAt);
            var vehiclePrice = vehicle.PricePerDay * rentalDays;
            var seasonalSurcharge = ReservationRules.GetSeasonalSurcharge(pickupAt, rentalDays, vehicle.PricePerDay, _seasons);
            var equipmentPrice = equipment.Sum(x => x.Quantity * x.PricePerDay * rentalDays);

            var reservation = new Reservation
            {
                UserId = customerId,
                VehicleId = vehicle.Id,
                PickupAt = pickupAt,
                ReturnAt = returnAt,
                RentalDays = rentalDays,
                VehiclePrice = vehiclePrice,
                SeasonalSurcharge = seasonalSurcharge,
                EquipmentPrice = equipmentPrice,
                TotalPrice = vehiclePrice + seasonalSurcharge + equipmentPrice,
                Status = ReservationStatus.Pending,
                CreatedAt = createdAt,
                Equipment = equipment
            };

            reservation.StatusHistory.Add(new ReservationStatusHistory
            {
                OldStatus = null,
                NewStatus = ReservationStatus.Pending,
                ChangedAt = createdAt,
                ChangedByUserId = customerId
            });

            Reservations.Add(reservation);
            Notify(ReservationNotifications.Created(reservation, vehicle.Name), createdAt);

            return reservation;
        }

        private DateTime Pay(Reservation reservation, string vehicleName, DateTime createdAt)
        {
            var paidAt = createdAt.AddMinutes(2);

            reservation.Payments.Add(new Payment
            {
                StripePaymentIntentId = $"pi_seed_{++_paymentNumber:D5}",
                Amount = reservation.TotalPrice,
                ChargedAmount = reservation.TotalPrice,
                Status = PaymentStatus.Paid,
                CreatedAt = createdAt,
                PaidAt = paidAt
            });

            Notify(ReservationNotifications.Paid(reservation, vehicleName, reservation.TotalPrice), paidAt);

            return paidAt;
        }

        private void Refund(Reservation reservation, string vehicleName, DateTime refundedAt)
        {
            var payment = reservation.Payments.Single();
            payment.Status = PaymentStatus.Refunded;
            payment.RefundedAt = refundedAt;
            payment.StripeRefundId = payment.StripePaymentIntentId.Replace("pi_", "re_");

            Notify(ReservationNotifications.Refunded(reservation, vehicleName, payment.ChargedAmount ?? payment.Amount), refundedAt);
        }

        private static DateTime ConfirmTime(DateTime paidAt, DateTime pickupAt, int index)
        {
            var confirmedAt = paidAt.AddMinutes(Cycle(ConfirmDelayMinutes, index));
            var latest = pickupAt.AddHours(-1);

            return confirmedAt < latest ? confirmedAt : Max(latest, paidAt.AddMinutes(5));
        }

        private DateTime Confirm(Reservation reservation, string vehicleName, DateTime confirmedAt)
        {
            ChangeStatus(reservation, ReservationStatus.Confirmed, confirmedAt, AdministratorId, null);
            Notify(ReservationNotifications.Confirmed(reservation, vehicleName), confirmedAt);

            return confirmedAt;
        }

        private void SendReminder(Reservation reservation, string vehicleName, DateTime confirmedAt, DateTime? cancelledAt)
        {
            var remindedAt = Max(reservation.PickupAt.AddHours(-ReservationRules.PickupReminderHours), confirmedAt.AddMinutes(5));

            if (remindedAt >= reservation.PickupAt || (cancelledAt.HasValue && remindedAt >= cancelledAt.Value))
            {
                return;
            }

            reservation.ReminderSentAt = remindedAt;
            Notify(ReservationNotifications.PickupReminder(reservation, vehicleName), remindedAt);
        }

        private void Reject(Reservation reservation, string vehicleName, DateTime rejectedAt, string reason)
        {
            ChangeStatus(reservation, ReservationStatus.Cancelled, rejectedAt, AdministratorId, reason);
            Notify(ReservationNotifications.Rejected(reservation, vehicleName, reason), rejectedAt);
            Refund(reservation, vehicleName, rejectedAt.AddMinutes(1));
        }

        private void CancelByCustomer(Reservation reservation, string vehicleName, DateTime cancelledAt, string? reason)
        {
            ChangeStatus(reservation, ReservationStatus.Cancelled, cancelledAt, reservation.UserId, reason);
            Notify(ReservationNotifications.CancelledByCustomer(reservation, vehicleName), cancelledAt);
            Refund(reservation, vehicleName, cancelledAt.AddMinutes(1));
        }

        private void CancelByAdministrator(Reservation reservation, string vehicleName, DateTime cancelledAt, string reason)
        {
            ChangeStatus(reservation, ReservationStatus.Cancelled, cancelledAt, AdministratorId, reason);
            Notify(ReservationNotifications.CancelledByAdministrator(reservation, vehicleName, reason), cancelledAt);
            Refund(reservation, vehicleName, cancelledAt.AddMinutes(1));
        }

        private void Expire(Reservation reservation, string vehicleName, DateTime createdAt)
        {
            var expiredAt = PaymentRules.GetPaymentDeadline(createdAt).AddMinutes(1);
            ChangeStatus(reservation, ReservationStatus.Cancelled, expiredAt, null, PaymentRules.ExpiredReason);
            Notify(ReservationNotifications.Expired(reservation, vehicleName), expiredAt);
        }

        private static void ChangeStatus(Reservation reservation, ReservationStatus newStatus, DateTime changedAt, int? changedByUserId,
            string? reason)
        {
            reservation.StatusHistory.Add(new ReservationStatusHistory
            {
                OldStatus = reservation.Status,
                NewStatus = newStatus,
                Reason = reason,
                ChangedAt = changedAt,
                ChangedByUserId = changedByUserId
            });

            reservation.Status = newStatus;
        }

        private void AddReview(Reservation reservation, DateTime completedAt, int index)
        {
            var createdAt = completedAt.AddHours(2 + index % 20);
            if (index % 3 == 2 || createdAt > _now.AddMinutes(-5))
            {
                return;
            }

            var rating = Math.Clamp(BaseRatings.GetValueOrDefault(reservation.VehicleId, 4)
                                    + Cycle(RatingOffsets, index * 7 + reservation.VehicleId), 1, 5);

            reservation.Review = new Review
            {
                Rating = rating,
                Comment = index % 6 == 5 ? null : Cycle(Comments[rating - 1], index),
                CreatedAt = createdAt
            };
        }

        private void Notify(Notification notification, DateTime createdAt)
        {
            notification.CreatedAt = createdAt;
            notification.IsRead = createdAt < _now.AddDays(-ReadAfterDays);
            Notifications.Add(notification);
        }

        private static DateTime Max(DateTime first, DateTime second) => first > second ? first : second;
    }
}
