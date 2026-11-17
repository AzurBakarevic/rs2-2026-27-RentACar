using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace RentACar.Services.Database.Configurations;

public class ReviewConfiguration : IEntityTypeConfiguration<Review>
{
    public void Configure(EntityTypeBuilder<Review> builder)
    {
        builder.ToTable(t => t.HasCheckConstraint("CK_Reviews_Rating", "[Rating] BETWEEN 1 AND 5"));

        builder.Property(x => x.Comment).HasMaxLength(1000);

        // Jedna recenzija po rezervaciji: FK u odnosu jedan-na-jedan dobija unique indeks.
        builder.HasOne(x => x.Reservation)
            .WithOne(x => x.Review)
            .HasForeignKey<Review>(x => x.ReservationId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
