using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace RentACar.Services.Database.Configurations;

public class ReservationStatusHistoryConfiguration : IEntityTypeConfiguration<ReservationStatusHistory>
{
    public void Configure(EntityTypeBuilder<ReservationStatusHistory> builder)
    {
        builder.Property(x => x.Reason).HasMaxLength(500);

        builder.HasIndex(x => new { x.ReservationId, x.ChangedAt });

        builder.HasOne(x => x.Reservation)
            .WithMany(x => x.StatusHistory)
            .HasForeignKey(x => x.ReservationId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.ChangedByUser)
            .WithMany()
            .HasForeignKey(x => x.ChangedByUserId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
