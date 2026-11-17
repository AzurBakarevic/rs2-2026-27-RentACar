using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace RentACar.Services.Database.Configurations;

public class ReservationConfiguration : IEntityTypeConfiguration<Reservation>
{
    public void Configure(EntityTypeBuilder<Reservation> builder)
    {
        builder.ToTable(t =>
        {
            t.HasCheckConstraint("CK_Reservations_Period", "[ReturnAt] > [PickupAt]");
            t.HasCheckConstraint("CK_Reservations_RentalDays", "[RentalDays] > 0");
        });

        builder.Property(x => x.VehiclePrice).HasPrecision(10, 2);
        builder.Property(x => x.SeasonalSurcharge).HasPrecision(10, 2);
        builder.Property(x => x.EquipmentPrice).HasPrecision(10, 2);
        builder.Property(x => x.TotalPrice).HasPrecision(10, 2);

        // Provjera zauzetosti vozila i preklapanja rezervacija korisnika ide po ovim kolonama.
        builder.HasIndex(x => new { x.VehicleId, x.PickupAt, x.ReturnAt });
        builder.HasIndex(x => new { x.UserId, x.PickupAt });
        builder.HasIndex(x => x.Status);

        builder.HasOne(x => x.User)
            .WithMany(x => x.Reservations)
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.Vehicle)
            .WithMany(x => x.Reservations)
            .HasForeignKey(x => x.VehicleId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
