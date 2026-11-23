using RentACar.Model.Requests;

namespace RentACar.WebAPI.Extensions;

public static class FormFileExtensions
{
    public const long MaxImageRequestBytes = 10 * 1024 * 1024;

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
