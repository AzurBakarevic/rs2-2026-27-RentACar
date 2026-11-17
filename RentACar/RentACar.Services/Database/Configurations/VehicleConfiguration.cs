using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace RentACar.Services.Database.Configurations;

public class VehicleConfiguration : IEntityTypeConfiguration<Vehicle>
{
    public void Configure(EntityTypeBuilder<Vehicle> builder)
    {
        builder.ToTable(t =>
        {
            t.HasCheckConstraint("CK_Vehicles_PricePerDay", "[PricePerDay] > 0");
            t.HasCheckConstraint("CK_Vehicles_SeatCount", "[SeatCount] > 0");
        });

        builder.Property(x => x.RegistrationNumber).IsRequired().HasMaxLength(20);
        builder.Property(x => x.Description).HasMaxLength(1000);
        builder.Property(x => x.PricePerDay).HasPrecision(10, 2);

        builder.HasIndex(x => x.RegistrationNumber).IsUnique();

        builder.HasOne(x => x.VehicleModel)
            .WithMany(x => x.Vehicles)
            .HasForeignKey(x => x.VehicleModelId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.Category)
            .WithMany(x => x.Vehicles)
            .HasForeignKey(x => x.CategoryId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.FuelType)
            .WithMany(x => x.Vehicles)
            .HasForeignKey(x => x.FuelTypeId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.TransmissionType)
            .WithMany(x => x.Vehicles)
            .HasForeignKey(x => x.TransmissionTypeId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
