using Mapster;
using RentACar.Model.Enums;
using RentACar.Model.Responses;
using RentACar.Services.Database;

namespace RentACar.Services.Mapping;

// Mapiranja koja Mapster ne može izvesti iz naziva svojstava. Koriste se u ProjectToType,
// pa se i ovi izrazi prevode u SQL (npr. prosječna ocjena se računa u bazi, bez učitavanja recenzija).
public class MappingConfig : IRegister
{
    public void Register(TypeAdapterConfig config)
    {
        config.NewConfig<Vehicle, VehicleResponse>()
            .Map(dest => dest.BrandId, src => src.VehicleModel.BrandId)
            .Map(dest => dest.BrandName, src => src.VehicleModel.Brand.Name)
            // Iz baze se čita samo da li slika postoji, a ne njeni bajtovi.
            .Map(dest => dest.HasImage, src => src.Image != null)
            .Map(dest => dest.AverageRating,
                src => src.Reservations.Where(r => r.Review != null).Average(r => (double?)r.Review!.Rating))
            .Map(dest => dest.ReviewCount, src => src.Reservations.Count(r => r.Review != null));

        // Kao kod vozila: iz baze se čita samo da li slika profila postoji.
        config.NewConfig<User, UserResponse>()
            .Map(dest => dest.HasProfileImage, src => src.ProfileImage != null);

        config.NewConfig<VehicleMaintenance, VehicleMaintenanceResponse>()
            .Map(dest => dest.VehicleName, src => src.Vehicle.VehicleModel.Brand.Name + " " + src.Vehicle.VehicleModel.Name);

        // Oprema, uplata i historija statusa se ne mapiraju ovdje: puni ih samo GetByIdAsync, posebnim upitima,
        // da lista rezervacija ne čita te tabele. AllowedActions računa state machine, a rok za plaćanje servis.
        config.NewConfig<Reservation, ReservationResponse>()
            .Map(dest => dest.UserFullName, src => src.User.FirstName + " " + src.User.LastName)
            .Map(dest => dest.VehicleName, src => src.Vehicle.VehicleModel.Brand.Name + " " + src.Vehicle.VehicleModel.Name)
            .Map(dest => dest.VehicleHasImage, src => src.Vehicle.Image != null)
            .Map(dest => dest.IsPaid, src => src.Payments.Any(p => p.Status == PaymentStatus.Paid))
            .Map(dest => dest.CancellationReason,
                src => src.StatusHistory.Where(h => h.NewStatus == ReservationStatus.Cancelled).Select(h => h.Reason).FirstOrDefault())
            .Ignore(dest => dest.AllowedActions)
            .Ignore(dest => dest.PaymentDeadline)
            .Ignore(dest => dest.Payment!)
            .Ignore(dest => dest.Equipment!)
            .Ignore(dest => dest.StatusHistory!);

        config.NewConfig<ReservationEquipment, ReservationEquipmentResponse>()
            .Map(dest => dest.TotalPrice, src => src.Quantity * src.PricePerDay * src.Reservation.RentalDays);

        // null = promjenu je izvršio sistem.
        config.NewConfig<ReservationStatusHistory, ReservationStatusHistoryResponse>()
            .Map(dest => dest.ChangedByName,
                src => src.ChangedByUser != null ? src.ChangedByUser.FirstName + " " + src.ChangedByUser.LastName : null);
    }
}
