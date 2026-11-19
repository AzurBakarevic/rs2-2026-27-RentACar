namespace RentACar.Worker;

// Vrijednosti dolaze iz .env-a (Smtp__Host, Smtp__Port, Smtp__UseSsl, Smtp__Username, Smtp__Password,
// Smtp__FromAddress), upute 3.3. Za Gmail: smtp.gmail.com, 587, UseSsl=true i app-lozinka Google naloga.
public class SmtpSettings
{
    public const string SectionName = "Smtp";

    public string Host { get; set; } = string.Empty;
    public int Port { get; set; }
    public bool UseSsl { get; set; }
    public string Username { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string FromAddress { get; set; } = string.Empty;

    // Bez ovih podataka Worker se ne pokreće, umjesto da svaki e-mail završi u redu neuspjelih.
    public void Validate()
    {
        if (string.IsNullOrWhiteSpace(Host) || Port <= 0)
        {
            throw new InvalidOperationException("SMTP host or port is missing. Set Smtp__Host and Smtp__Port in the .env file.");
        }

        if (string.IsNullOrWhiteSpace(FromAddress))
        {
            throw new InvalidOperationException("SMTP sender address is missing. Set Smtp__FromAddress in the .env file.");
        }

        // Server bez prijave (bez korisničkog imena i lozinke) je dozvoljen, ali ne samo jedno od to dvoje.
        if (string.IsNullOrWhiteSpace(Username) != string.IsNullOrWhiteSpace(Password))
        {
            throw new InvalidOperationException("Set both Smtp__Username and Smtp__Password in the .env file, or neither.");
        }
    }
}
