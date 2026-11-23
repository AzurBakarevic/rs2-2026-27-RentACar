using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace RentACar.Services.Database.Configurations;

public class UserConfiguration : IEntityTypeConfiguration<User>
{
    public void Configure(EntityTypeBuilder<User> builder)
    {
        builder.Property(x => x.FirstName).IsRequired().HasMaxLength(50);
        builder.Property(x => x.LastName).IsRequired().HasMaxLength(50);
        builder.Property(x => x.Email).IsRequired().HasMaxLength(100);
        builder.Property(x => x.PhoneNumber).IsRequired().HasMaxLength(30);
        builder.Property(x => x.Username).IsRequired().HasMaxLength(50);
        builder.Property(x => x.PasswordHash).IsRequired().HasMaxLength(200);
        builder.Property(x => x.PasswordSalt).IsRequired().HasMaxLength(200);
        builder.Property(x => x.DriverLicenseNumber).HasMaxLength(30);

        builder.HasIndex(x => x.Email).IsUnique().HasFilter("[IsDeleted] = 0");
        builder.HasIndex(x => x.Username).IsUnique().HasFilter("[IsDeleted] = 0");

        builder.HasOne(x => x.Role)
            .WithMany(x => x.Users)
            .HasForeignKey(x => x.RoleId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
