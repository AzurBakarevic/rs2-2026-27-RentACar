namespace RentACar.Model.Messaging;

// Poruka koju API šalje na RabbitMQ, a Worker je čita i šalje kao e-mail (upute 3.2).
// Tekst sastavlja API (isti kao u notifikaciji), a Worker ga samo dostavlja.
public class EmailMessage
{
    public string To { get; set; } = string.Empty;
    public string ToName { get; set; } = string.Empty;
    public string Subject { get; set; } = string.Empty;
    public string Body { get; set; } = string.Empty;
}
