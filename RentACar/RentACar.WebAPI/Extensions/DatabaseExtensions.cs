using Microsoft.EntityFrameworkCore;
using RentACar.Services.Database;

namespace RentACar.WebAPI.Extensions;

public static class DatabaseExtensions
{
    private const string ConnectionStringName = "RentACar";

    public static IServiceCollection AddRentACarDatabase(this IServiceCollection services, IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString(ConnectionStringName);
        if (string.IsNullOrWhiteSpace(connectionString))
        {
            throw new InvalidOperationException(
                $"Connection string is missing. Set ConnectionStrings__{ConnectionStringName} in the .env file.");
        }

        services.AddDbContext<RentACarDbContext>(options => options.UseSqlServer(connectionString));

        return services;
    }

    public static async Task MigrateDatabaseAsync(this WebApplication app)
    {
        using var scope = app.Services.CreateScope();
        var logger = scope.ServiceProvider.GetRequiredService<ILoggerFactory>().CreateLogger(nameof(DatabaseExtensions));
        var dbContext = scope.ServiceProvider.GetRequiredService<RentACarDbContext>();

        logger.LogInformation("Applying database migrations...");
        await dbContext.Database.MigrateAsync();

        var seededImages = await dbContext.SeedVehicleImagesAsync();
        if (seededImages > 0)
        {
            logger.LogInformation("Seeded images for {Count} vehicles.", seededImages);
        }

        var seededProfileImages = await dbContext.SeedUserImagesAsync();
        if (seededProfileImages > 0)
        {
            logger.LogInformation("Seeded profile images for {Count} users.", seededProfileImages);
        }

        var seededReservations = await dbContext.SeedReservationHistoryAsync();
        if (seededReservations > 0)
        {
            logger.LogInformation("Seeded {Count} past reservations.", seededReservations);
        }

        logger.LogInformation("Database is up to date.");
    }
}
