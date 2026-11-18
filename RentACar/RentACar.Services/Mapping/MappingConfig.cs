using Mapster;
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

        config.NewConfig<VehicleMaintenance, VehicleMaintenanceResponse>()
            .Map(dest => dest.VehicleName, src => src.Vehicle.VehicleModel.Brand.Name + " " + src.Vehicle.VehicleModel.Name);
    }
}
