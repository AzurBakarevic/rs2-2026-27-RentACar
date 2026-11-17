using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace RentACar.Services.Database.Configurations;

public class ReservationEquipmentConfiguration : IEntityTypeConfiguration<ReservationEquipment>
{
    public void Configure(EntityTypeBuilder<ReservationEquipment> builder)
    {
        builder.ToTable(t => t.HasCheckConstraint("CK_ReservationEquipment_Quantity", "[Quantity] > 0"));

        builder.Property(x => x.PricePerDay).HasPrecision(10, 2);

        builder.HasIndex(x => new { x.ReservationId, x.EquipmentId }).IsUnique();

        builder.HasOne(x => x.Reservation)
            .WithMany(x => x.Equipment)
            .HasForeignKey(x => x.ReservationId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.Equipment)
            .WithMany(x => x.ReservationItems)
            .HasForeignKey(x => x.EquipmentId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
