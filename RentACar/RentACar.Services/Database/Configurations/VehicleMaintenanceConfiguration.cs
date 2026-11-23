using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace RentACar.Services.Database.Configurations;

public class VehicleMaintenanceConfiguration : IEntityTypeConfiguration<VehicleMaintenance>
{
    public void Configure(EntityTypeBuilder<VehicleMaintenance> builder)
    {
        builder.ToTable(t =>
        {
            t.HasCheckConstraint("CK_VehicleMaintenances_Period", "[EndAt] > [StartAt]");
            t.HasCheckConstraint("CK_VehicleMaintenances_Cost", "[Cost] >= 0");
        });

        builder.Property(x => x.Description).IsRequired().HasMaxLength(500);
        builder.Property(x => x.Cost).HasPrecision(10, 2);

        builder.HasIndex(x => new { x.VehicleId, x.StartAt, x.EndAt });

        builder.HasOne(x => x.Vehicle)
            .WithMany(x => x.Maintenances)
            .HasForeignKey(x => x.VehicleId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
