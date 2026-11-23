namespace RentACar.Services.Helpers;

public static class ImageFormat
{
    public const string Jpeg = "image/jpeg";
    public const string Png = "image/png";

    public static readonly string[] AllowedContentTypes = [Jpeg, Png];

    private static readonly byte[] JpegSignature = [0xFF, 0xD8, 0xFF];
    private static readonly byte[] PngSignature = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];

    public static string? DetectContentType(ReadOnlySpan<byte> content)
    {
        if (content.StartsWith(JpegSignature))
        {
            return Jpeg;
        }

        if (content.StartsWith(PngSignature))
        {
            return Png;
        }

        return null;
    }
}
