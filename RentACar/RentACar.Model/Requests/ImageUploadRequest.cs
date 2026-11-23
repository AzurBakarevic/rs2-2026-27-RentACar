namespace RentACar.Model.Requests;

public class ImageUploadRequest
{
    public byte[] Content { get; set; } = [];

    public string? ContentType { get; set; }
}
