using System.Security.Cryptography;
using System.Text;
using RentACar.Services.Interfaces;

namespace RentACar.Services.Implementations;

public class CryptoService : ICryptoService
{
    private const int SaltSize = 16;
    private const int HashSize = 32;
    private const int Iterations = 100_000;

    public string GenerateSalt()
    {
        return Convert.ToBase64String(RandomNumberGenerator.GetBytes(SaltSize));
    }

    public string GenerateHash(string password, string salt)
    {
        var hash = Rfc2898DeriveBytes.Pbkdf2(
            Encoding.UTF8.GetBytes(password),
            Convert.FromBase64String(salt),
            Iterations,
            HashAlgorithmName.SHA256,
            HashSize);

        return Convert.ToBase64String(hash);
    }

    public bool Verify(string hash, string salt, string password)
    {
        var expected = Convert.FromBase64String(hash);
        var actual = Convert.FromBase64String(GenerateHash(password, salt));

        return CryptographicOperations.FixedTimeEquals(expected, actual);
    }
}
