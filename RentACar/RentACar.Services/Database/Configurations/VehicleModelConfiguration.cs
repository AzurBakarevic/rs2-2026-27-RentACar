using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace RentACar.Services.Database.Configurations;

public class VehicleModelConfiguration : IEntityTypeConfiguration<VehicleModel>
{
    public void Configure(EntityTypeBuilder<VehicleModel> builder)
    {
        builder.Property(x => x.Name).IsRequired().HasMaxLength(50);
        builder.HasIndex(x => new { x.BrandId, x.Name }).IsUnique();

        builder.HasOne(x => x.Brand)
            .WithMany(x => x.Models)
            .HasForeignKey(x => x.BrandId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
