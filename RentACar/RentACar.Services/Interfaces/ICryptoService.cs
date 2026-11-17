namespace RentACar.Services.Interfaces;

public interface ICryptoService
{
    string GenerateSalt();
    string GenerateHash(string password, string salt);
    bool Verify(string hash, string salt, string password);
}
