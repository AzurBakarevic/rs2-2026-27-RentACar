namespace RentACar.Services.Helpers;

// Prepoznaje format slike po prvim bajtovima sadržaja (magic bytes), a ne po ekstenziji
// ili MIME tipu koji šalje klijent (upute 5).
public static class ImageFormat
{
    public const string Jpeg = "image/jpeg";
    public const string Png = "image/png";

    public static readonly string[] AllowedContentTypes = [Jpeg, Png];

    private static readonly byte[] JpegSignature = [0xFF, 0xD8, 0xFF];
    private static readonly byte[] PngSignature = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];

    // MIME tip prepoznat iz sadržaja ili null ako sadržaj nije ni JPEG ni PNG.
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
