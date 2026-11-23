using Microsoft.EntityFrameworkCore;

namespace RentACar.Services.Database;

public static class DatabaseImageSeed
{
    private const string VehicleImageResourcePrefix = "SeedImages.vehicle-";

    public static async Task<int> SeedVehicleImagesAsync(this RentACarDbContext dbContext)
    {
        var assembly = typeof(DatabaseImageSeed).Assembly;

        var vehicles = await dbContext.Vehicles
            .Where(x => x.Image == null && x.CreatedAt == DatabaseSeed.SeedDate)
            .ToListAsync();

        foreach (var vehicle in vehicles)
        {
            await using var stream = assembly.GetManifestResourceStream($"{VehicleImageResourcePrefix}{vehicle.Id}.jpg");
            if (stream == null)
            {
                continue;
            }

            using var memory = new MemoryStream();
            await stream.CopyToAsync(memory);
            vehicle.Image = memory.ToArray();
        }

        return await dbContext.SaveChangesAsync();
    }
}
