using Microsoft.EntityFrameworkCore;
using RentACar.Model.Constants;

namespace RentACar.Services.Database;

public static class DatabaseSeed
{
    // HasData traži fiksne vrijednosti, inače bi svaka nova migracija mijenjala seed.
    private static readonly DateTime SeedDate = new(2026, 11, 1, 0, 0, 0, DateTimeKind.Utc);

    public static void Seed(this ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Role>().HasData(
            new Role { Id = 1, Name = RoleNames.Administrator },
            new Role { Id = 2, Name = RoleNames.Customer });

        modelBuilder.Entity<Brand>().HasData(
            new Brand { Id = 1, Name = "Volkswagen" },
            new Brand { Id = 2, Name = "Škoda" },
            new Brand { Id = 3, Name = "Toyota" },
            new Brand { Id = 4, Name = "Renault" },
            new Brand { Id = 5, Name = "Dacia" },
            new Brand { Id = 6, Name = "Hyundai" });

        modelBuilder.Entity<VehicleModel>().HasData(
            new VehicleModel { Id = 1, BrandId = 1, Name = "Golf" },
            new VehicleModel { Id = 2, BrandId = 1, Name = "Polo" },
            new VehicleModel { Id = 3, BrandId = 1, Name = "Passat" },
            new VehicleModel { Id = 4, BrandId = 2, Name = "Octavia" },
            new VehicleModel { Id = 5, BrandId = 2, Name = "Fabia" },
            new VehicleModel { Id = 6, BrandId = 3, Name = "RAV4" },
            new VehicleModel { Id = 7, BrandId = 3, Name = "Yaris" },
            new VehicleModel { Id = 8, BrandId = 4, Name = "Clio" },
            new VehicleModel { Id = 9, BrandId = 4, Name = "Megane" },
            new VehicleModel { Id = 10, BrandId = 5, Name = "Duster" },
            new VehicleModel { Id = 11, BrandId = 5, Name = "Sandero" },
            new VehicleModel { Id = 12, BrandId = 6, Name = "Tucson" });

        modelBuilder.Entity<Category>().HasData(
            new Category { Id = 1, Name = "Malo" },
            new Category { Id = 2, Name = "Kompakt" },
            new Category { Id = 3, Name = "Limuzina" },
            new Category { Id = 4, Name = "Karavan" },
            new Category { Id = 5, Name = "SUV" });

        modelBuilder.Entity<FuelType>().HasData(
            new FuelType { Id = 1, Name = "Benzin" },
            new FuelType { Id = 2, Name = "Dizel" },
            new FuelType { Id = 3, Name = "Hibrid" },
            new FuelType { Id = 4, Name = "Električni" });

        modelBuilder.Entity<TransmissionType>().HasData(
            new TransmissionType { Id = 1, Name = "Manuelni" },
            new TransmissionType { Id = 2, Name = "Automatski" });

        modelBuilder.Entity<Vehicle>().HasData(
            Vehicle(1, 1, "A12-K-345", 2021, 2, 2, 1, 70m, "Pouzdan kompaktni automobil, idealan za grad i duža putovanja."),
            Vehicle(2, 4, "E45-M-678", 2022, 3, 2, 2, 85m, "Prostrana limuzina sa velikim prtljažnikom."),
            Vehicle(3, 6, "K67-A-234", 2023, 5, 3, 2, 120m, "Hibridni SUV sa pogonom na sva četiri točka."),
            Vehicle(4, 8, "J23-T-901", 2020, 1, 1, 1, 50m, "Ekonomičan gradski automobil.", isActive: false),
            Vehicle(5, 10, "M34-E-512", 2022, 5, 2, 1, 75m, "Robustan SUV za loše puteve i planinu."),
            Vehicle(6, 2, "T56-O-789", 2021, 1, 1, 1, 55m, "Mali automobil, jednostavan za parkiranje."),
            Vehicle(7, 3, "O78-J-123", 2022, 4, 2, 2, 95m, "Karavan za porodična putovanja."),
            Vehicle(8, 7, "A90-K-456", 2023, 1, 3, 2, 60m, "Hibridni gradski automobil sa malom potrošnjom."),
            Vehicle(9, 12, "E11-T-222", 2024, 5, 2, 2, 110m, "Novi SUV sa bogatom opremom."),
            Vehicle(10, 5, "K33-M-333", 2021, 1, 1, 1, 50m, "Praktičan mali automobil za grad."));

        modelBuilder.Entity<Equipment>().HasData(
            new Equipment { Id = 1, Name = "Dječija sjedalica", PricePerDay = 10m, Quantity = 4 },
            new Equipment { Id = 2, Name = "Navigacija", PricePerDay = 8m, Quantity = 5 },
            new Equipment { Id = 3, Name = "Krovni nosač", PricePerDay = 12m, Quantity = 2 },
            new Equipment { Id = 4, Name = "Lanci za snijeg", PricePerDay = 5m, Quantity = 6 });

        modelBuilder.Entity<SeasonalPrice>().HasData(
            new SeasonalPrice
            {
                Id = 1,
                Name = "Zimski praznici",
                StartDate = new DateOnly(2026, 12, 20),
                EndDate = new DateOnly(2027, 1, 5),
                IncreasePercentage = 10m
            },
            new SeasonalPrice
            {
                Id = 2,
                Name = "Ljetna sezona",
                StartDate = new DateOnly(2027, 6, 15),
                EndDate = new DateOnly(2027, 9, 15),
                IncreasePercentage = 20m
            });
    }

    private static Vehicle Vehicle(int id, int modelId, string registration, int year, int categoryId,
        int fuelTypeId, int transmissionTypeId, decimal pricePerDay, string description, bool isActive = true) =>
        new()
        {
            Id = id,
            VehicleModelId = modelId,
            RegistrationNumber = registration,
            ProductionYear = year,
            SeatCount = 5,
            CategoryId = categoryId,
            FuelTypeId = fuelTypeId,
            TransmissionTypeId = transmissionTypeId,
            PricePerDay = pricePerDay,
            Description = description,
            IsActive = isActive,
            CreatedAt = SeedDate
        };
}
