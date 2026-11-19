namespace RentACar.Model.Messaging;

// Vrijednosti dolaze iz .env-a (RabbitMQ__Host, RabbitMQ__Port, RabbitMQ__Username, RabbitMQ__Password), upute 3.3.
// Koriste ih i API i Worker.
public class RabbitMqSettings
{
    public const string SectionName = "RabbitMQ";

    public string Host { get; set; } = string.Empty;
    public int Port { get; set; }
    public string Username { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;

    // Bez ovih podataka servis se ne pokreće, umjesto da padne tek pri prvoj poruci.
    public void Validate()
    {
        if (string.IsNullOrWhiteSpace(Host) || Port <= 0)
        {
            throw new InvalidOperationException("RabbitMQ host or port is missing. Set RabbitMQ__Host and RabbitMQ__Port in the .env file.");
        }

        if (string.IsNullOrWhiteSpace(Username) || string.IsNullOrWhiteSpace(Password))
        {
            throw new InvalidOperationException("RabbitMQ credentials are missing. Set RabbitMQ__Username and RabbitMQ__Password in the .env file.");
        }
    }
}
