using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace RentACar.Services.Database.Configurations;

public class RecommendationModelConfiguration : IEntityTypeConfiguration<RecommendationModel>
{
    public void Configure(EntityTypeBuilder<RecommendationModel> builder)
    {
        builder.Property(x => x.Data).IsRequired();
        builder.Property(x => x.DataHash).IsRequired().HasMaxLength(64);
    }
}
