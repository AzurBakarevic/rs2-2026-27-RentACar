using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using RentACar.Model.Enums;

namespace RentACar.Services.Database.Configurations;

public class PaymentConfiguration : IEntityTypeConfiguration<Payment>
{
    public void Configure(EntityTypeBuilder<Payment> builder)
    {
        builder.Property(x => x.StripePaymentIntentId).IsRequired().HasMaxLength(100);
        builder.Property(x => x.StripeRefundId).HasMaxLength(100);
        builder.Property(x => x.Amount).HasPrecision(10, 2);
        builder.Property(x => x.ChargedAmount).HasPrecision(10, 2);

        builder.HasIndex(x => x.StripePaymentIntentId).IsUnique();

        // Jedna rezervacija može imati najviše jedno plaćanje koje nije poništeno
        // (otvoreno, plaćeno ili vraćeno), čime se sprječava višestruko plaćanje (upute 7.1).
        builder.HasIndex(x => x.ReservationId)
            .IsUnique()
            .HasFilter($"[Status] <> {(int)PaymentStatus.Cancelled}");

        builder.HasOne(x => x.Reservation)
            .WithMany(x => x.Payments)
            .HasForeignKey(x => x.ReservationId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
