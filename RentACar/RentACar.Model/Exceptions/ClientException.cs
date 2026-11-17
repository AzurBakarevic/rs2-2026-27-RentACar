namespace RentACar.Model.Exceptions;

// Kršenje poslovnog pravila. Poruka je namijenjena korisniku (na bosanskom); ExceptionFilter je vraća kao 400.
public class ClientException : Exception
{
    public ClientException(string message) : base(message)
    {
    }
}
