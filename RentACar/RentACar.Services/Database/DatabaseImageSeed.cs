using Microsoft.EntityFrameworkCore;

namespace RentACar.Services.Database;

public static class DatabaseImageSeed
{
    private const string VehicleImageResourcePrefix = "SeedImages.vehicle-";
    private const string UserImageResourcePrefix = "SeedImages.user-";

    public static async Task<int> SeedVehicleImagesAsync(this RentACarDbContext dbContext)
    {
        var vehicles = await dbContext.Vehicles
            .Where(x => x.Image == null && x.CreatedAt == DatabaseSeed.SeedDate)
            .ToListAsync();

        foreach (var vehicle in vehicles)
        {
            vehicle.Image = await ReadResourceAsync($"{VehicleImageResourcePrefix}{vehicle.Id}.jpg");
        }

        return await dbContext.SaveChangesAsync();
    }

    public static async Task<int> SeedUserImagesAsync(this RentACarDbContext dbContext)
    {
        var users = await dbContext.Users
            .Where(x => x.ProfileImage == null && !x.IsDeleted && x.CreatedAt == DatabaseSeed.SeedDate)
            .ToListAsync();

        foreach (var user in users)
        {
            user.ProfileImage = await ReadResourceAsync($"{UserImageResourcePrefix}{user.Id}.jpg");
        }

        return await dbContext.SaveChangesAsync();
    }

    private static async Task<byte[]?> ReadResourceAsync(string name)
    {
        await using var stream = typeof(DatabaseImageSeed).Assembly.GetManifestResourceStream(name);
        if (stream == null)
        {
            return null;
        }

        using var memory = new MemoryStream();
        await stream.CopyToAsync(memory);
        return memory.ToArray();
    }
}
