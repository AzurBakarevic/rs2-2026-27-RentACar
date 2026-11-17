using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace RentACar.Services.Database.Configurations;

public class EquipmentConfiguration : IEntityTypeConfiguration<Equipment>
{
    public void Configure(EntityTypeBuilder<Equipment> builder)
    {
        builder.ToTable(t =>
        {
            t.HasCheckConstraint("CK_Equipment_PricePerDay", "[PricePerDay] >= 0");
            t.HasCheckConstraint("CK_Equipment_Quantity", "[Quantity] >= 0");
        });

        builder.Property(x => x.Name).IsRequired().HasMaxLength(100);
        builder.Property(x => x.PricePerDay).HasPrecision(10, 2);

        builder.HasIndex(x => x.Name).IsUnique();
    }
}
