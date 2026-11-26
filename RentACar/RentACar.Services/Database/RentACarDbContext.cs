using Microsoft.EntityFrameworkCore;

namespace RentACar.Services.Database;

public class RentACarDbContext(DbContextOptions<RentACarDbContext> options) : DbContext(options)
{
    public DbSet<Role> Roles => Set<Role>();
    public DbSet<User> Users => Set<User>();
    public DbSet<Brand> Brands => Set<Brand>();
    public DbSet<VehicleModel> VehicleModels => Set<VehicleModel>();
    public DbSet<Category> Categories => Set<Category>();
    public DbSet<FuelType> FuelTypes => Set<FuelType>();
    public DbSet<TransmissionType> TransmissionTypes => Set<TransmissionType>();
    public DbSet<Vehicle> Vehicles => Set<Vehicle>();
    public DbSet<VehicleMaintenance> VehicleMaintenances => Set<VehicleMaintenance>();
    public DbSet<Equipment> Equipment => Set<Equipment>();
    public DbSet<SeasonalPrice> SeasonalPrices => Set<SeasonalPrice>();
    public DbSet<Reservation> Reservations => Set<Reservation>();
    public DbSet<ReservationEquipment> ReservationEquipment => Set<ReservationEquipment>();
    public DbSet<ReservationStatusHistory> ReservationStatusHistory => Set<ReservationStatusHistory>();
    public DbSet<Payment> Payments => Set<Payment>();
    public DbSet<Review> Reviews => Set<Review>();
    public DbSet<Notification> Notifications => Set<Notification>();
    public DbSet<PasswordResetCode> PasswordResetCodes => Set<PasswordResetCode>();
    public DbSet<RecommendationModel> RecommendationModels => Set<RecommendationModel>();

    protected override void ConfigureConventions(ModelConfigurationBuilder configurationBuilder)
    {
        configurationBuilder.Properties<DateTime>().HaveConversion<UtcDateTimeConverter>();
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(RentACarDbContext).Assembly);
        modelBuilder.Seed();
    }
}
