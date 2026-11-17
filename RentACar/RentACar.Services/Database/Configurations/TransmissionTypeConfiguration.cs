using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace RentACar.Services.Database.Configurations;

public class TransmissionTypeConfiguration : IEntityTypeConfiguration<TransmissionType>
{
    public void Configure(EntityTypeBuilder<TransmissionType> builder)
    {
        builder.Property(x => x.Name).IsRequired().HasMaxLength(50);
        builder.HasIndex(x => x.Name).IsUnique();
    }
}
