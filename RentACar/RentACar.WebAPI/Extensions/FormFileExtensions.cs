using RentACar.Model.Requests;

namespace RentACar.WebAPI.Extensions;

// Upload slike (vozilo, slika profila): fajl stiže kao multipart/form-data, da uz sadržaj stigne i MIME tip (upute 5).
public static class FormFileExtensions
{
    // Gornja granica veličine zahtjeva za upload; dozvoljenu veličinu slike (2 MB) provjerava validator, s jasnom porukom.
    public const long MaxImageRequestBytes = 10 * 1024 * 1024;

    // Bez fajla ostaje prazan sadržaj, pa validator vraća poruku "Odaberite sliku.".
    public static async Task<ImageUploadRequest> ToImageUploadRequestAsync(this IFormFile? file)
    {
        var request = new ImageUploadRequest { ContentType = file?.ContentType };

        if (file != null)
        {
            using var stream = new MemoryStream();
            await file.CopyToAsync(stream);
            request.Content = stream.ToArray();
        }

        return request;
    }
}
