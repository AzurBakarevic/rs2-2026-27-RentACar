using Microsoft.EntityFrameworkCore;

namespace RentACar.Services.Database;

// Slike seedanih vozila (upute 3.1: seed mora sadržavati i slike). Nisu u HasData, jer bi se bajtovi slika
// ponavljali u svakoj novoj migraciji i snapshotu. Nalaze se u projektu kao EmbeddedResource
// (Database/SeedImages/vehicle-{Id}.jpg) i upisuju se pri pokretanju, samo seedanim vozilima koja još nemaju sliku.
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
