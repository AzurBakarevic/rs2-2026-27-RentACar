namespace RentACar.Model.Responses;

// Fajl za preuzimanje (npr. PDF izvještaj); kontroler ga vraća s nazivom, pa ga aplikacija sprema pod tim imenom.
public class FileResponse
{
    public byte[] Content { get; set; } = [];
    public string ContentType { get; set; } = string.Empty;
    public string FileName { get; set; } = string.Empty;
}
