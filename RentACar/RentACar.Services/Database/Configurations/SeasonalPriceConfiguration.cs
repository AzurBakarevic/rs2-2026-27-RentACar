using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace RentACar.Services.Database.Configurations;

public class SeasonalPriceConfiguration : IEntityTypeConfiguration<SeasonalPrice>
{
    public void Configure(EntityTypeBuilder<SeasonalPrice> builder)
    {
        builder.ToTable(t =>
        {
            t.HasCheckConstraint("CK_SeasonalPrices_Period", "[EndDate] >= [StartDate]");
            t.HasCheckConstraint("CK_SeasonalPrices_IncreasePercentage", "[IncreasePercentage] > 0");
        });

        builder.Property(x => x.Name).IsRequired().HasMaxLength(100);
        builder.Property(x => x.IncreasePercentage).HasPrecision(5, 2);
    }
}
