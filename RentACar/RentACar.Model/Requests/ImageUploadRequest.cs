namespace RentACar.Model.Requests;

// Sadržaj uploadovanog fajla; kontroler ga puni iz multipart/form-data zahtjeva.
public class ImageUploadRequest
{
    public byte[] Content { get; set; } = [];

    // MIME tip koji je poslao klijent (npr. image/jpeg); provjerava se i prema stvarnom sadržaju (magic bytes).
    public string? ContentType { get; set; }
}
