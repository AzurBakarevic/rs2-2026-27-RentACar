using Microsoft.EntityFrameworkCore;
using RentACar.Model.Constants;

namespace RentACar.Services.Database;

public static class DatabaseSeed
{
    internal static readonly DateTime SeedDate = new(2025, 1, 1, 0, 0, 0, DateTimeKind.Utc);

    public static void Seed(this ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Role>().HasData(
            new Role { Id = 1, Name = RoleNames.Administrator },
            new Role { Id = 2, Name = RoleNames.Customer });

        modelBuilder.Entity<User>().HasData(
            new User
            {
                Id = 1,
                FirstName = "Desktop",
                LastName = "Administrator",
                Email = "desktop@rentacar.ba",
                PhoneNumber = "+387 61 000 001",
                Username = "desktop",
                PasswordHash = "bpKhlFuFnXOr/mgD1B3opMA3Kwvj6BtWeeD6HNxMKs4=",
                PasswordSalt = "XFq/dUV9C+XN/eJuP7yecQ==",
                IsActive = true,
                CreatedAt = SeedDate,
                RoleId = 1
            },
            new User
            {
                Id = 2,
                FirstName = "Mobile",
                LastName = "Korisnik",
                Email = "mobile@rentacar.ba",
                PhoneNumber = "+387 61 000 002",
                Username = "mobile",
                PasswordHash = "2Wg9Cdny4XenV98HS7I2Dta6f4KdSPy2ZBspXxtBgsU=",
                PasswordSalt = "4nkpZcAsz3yJjiRaT/LzfQ==",
                DriverLicenseNumber = "B1234567",
                DriverLicenseValidUntil = new DateOnly(2030, 12, 31),
                IsActive = true,
                CreatedAt = SeedDate,
                RoleId = 2
            },
            Customer(3, "Amar", "Hodžić", "+387 61 482 115", "B2045871", new DateOnly(2031, 5, 14),
                "lzE40nRVpxBs+MVoHgIdwA8/O5NS9dK3wHethUpCwns=", "9Uta9HEWzBKuy6UV1fVumg=="),
            Customer(4, "Senad", "Begović", "+387 62 315 904", "B1187342", new DateOnly(2029, 3, 2),
                "P2yvjqSKQ+gRoilb91v5koztyp2YY12hhAcZSnCygqE=", "PFJxm05K4Z4U6BJurntsQQ=="),
            Customer(5, "Kenan", "Mujić", "+387 61 774 230", "B3390126", new DateOnly(2032, 9, 21),
                "kMkhg2Ra+Khfp1fLb1RGwGt0z1FgxXi9a2xVLbG2MxE=", "3azjIXMUIVDGzOb/R19W7w=="),
            Customer(6, "Emir", "Delić", "+387 63 208 657", "B2861457", new DateOnly(2030, 1, 30),
                "45ZaA048t1kSMdMtZN9cXwFdcxxGe573HPfZpTqQ+eM=", "uQnOdmkhAmNggVXDv2U/oA=="),
            Customer(7, "Haris", "Šabić", "+387 65 541 398", "B3012784", new DateOnly(2033, 6, 8),
                "TFqxyzCPJmdwqd0lit6jWSGDbcX4YLGmYLtgqZlJ6r4=", "T6DZwYRtb5t5AzwGCkPoQA=="),
            Customer(8, "Tarik", "Kovačević", "+387 66 129 870", "B3547219", new DateOnly(2034, 2, 17),
                "XDKuFLEyNy3uRt7QZFINkdtWoFjWdgi94FroONFTLEE=", "Khlnvdj0evmCcBSlWePOWg=="),
            Customer(9, "Lejla", "Hasić", "+387 61 903 462", "B2493068", new DateOnly(2031, 11, 3),
                "AkRRBr1+3epfdxee5s+3NJ2axyMofOysbSMSjVXbXRE=", "wQ7OxgBgjaMEzhSOBEatXQ=="),
            Customer(10, "Amina", "Omerović", "+387 62 650 781", "B1958340", new DateOnly(2029, 8, 25),
                "mSbIM9LETI4VbpPdQdAErACvl2XxhgFxSmTredIZew4=", "K02GgsZdenkWUtRZAZ8uPA=="),
            Customer(11, "Selma", "Karić", "+387 61 237 514", "B2718903", new DateOnly(2032, 4, 12),
                "WcPz9siPE2OiYjzFo3T4Ejuyzannptp9+j7o3dKtjnM=", "52o15A9Ov9G5tj8DP7UKrQ=="),
            Customer(12, "Ajla", "Mehmedović", "+387 63 486 029", "B3204675", new DateOnly(2033, 10, 9),
                "ZkTYwE0+sCbPIxEQ3FLosvN8voWhxSHk2my+EAcQPwo=", "2rqNRUP5FiPTMVnDdBYIvw=="),
            Customer(13, "Merima", "Avdić", "+387 61 815 346", "B1640592", new DateOnly(2030, 7, 19),
                "MKWjXeSrzESg2il8YJrms3qpX79hxNzSVD4I1mG20cc=", "YdG9VTrIAys4Vn59HsyuUg==", isActive: false),
            Customer(14, "Džana", "Softić", "+387 62 097 153", "B3681240", new DateOnly(2034, 12, 1),
                "ogyFhNie3Qehc9zQT1EYjfdtGr+coquO7je/AfqToSE=", "OAfAfPJU6wz8cPuxVP2xrg=="));

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
            },
            new SeasonalPrice
            {
                Id = 3,
                Name = "Zimski praznici 2025/26",
                StartDate = new DateOnly(2025, 12, 20),
                EndDate = new DateOnly(2026, 1, 5),
                IncreasePercentage = 10m
            },
            new SeasonalPrice
            {
                Id = 4,
                Name = "Ljetna sezona 2026",
                StartDate = new DateOnly(2026, 6, 15),
                EndDate = new DateOnly(2026, 9, 15),
                IncreasePercentage = 20m
            });
    }

    private static User Customer(int id, string firstName, string lastName, string phoneNumber, string driverLicenseNumber,
        DateOnly driverLicenseValidUntil, string passwordHash, string passwordSalt, bool isActive = true)
    {
        var username = $"{Ascii(firstName)}.{Ascii(lastName)}";

        return new User
        {
            Id = id,
            FirstName = firstName,
            LastName = lastName,
            Email = $"{username}@example.com",
            PhoneNumber = phoneNumber,
            Username = username,
            PasswordHash = passwordHash,
            PasswordSalt = passwordSalt,
            DriverLicenseNumber = driverLicenseNumber,
            DriverLicenseValidUntil = driverLicenseValidUntil,
            IsActive = isActive,
            CreatedAt = SeedDate,
            RoleId = 2
        };
    }

    private static string Ascii(string value) => value.ToLowerInvariant()
        .Replace("dž", "dz").Replace("č", "c").Replace("ć", "c").Replace("š", "s").Replace("ž", "z").Replace("đ", "dj");

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
