namespace RentACar.Model.Messaging;

public class RabbitMqSettings
{
    public const string SectionName = "RabbitMQ";

    public string Host { get; set; } = string.Empty;
    public int Port { get; set; }
    public string Username { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;

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
