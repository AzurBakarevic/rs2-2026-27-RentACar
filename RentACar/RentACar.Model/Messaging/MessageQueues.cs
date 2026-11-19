namespace RentACar.Model.Messaging;

// Nazivi redova na RabbitMQ-u, zajednički za API (šalje) i Worker (čita). Oba deklarišu red istim argumentima,
// pa svejedno koji se prvi pokrene.
public static class MessageQueues
{
    public const string Emails = "rentacar.emails";

    // E-mail koji Worker ne pošalje ni nakon svih pokušaja ne gubi se, nego prelazi u ovaj red (upute A.1).
    public const string FailedEmails = "rentacar.emails.failed";

    public static IDictionary<string, object?> EmailQueueArguments => new Dictionary<string, object?>
    {
        ["x-dead-letter-exchange"] = string.Empty,
        ["x-dead-letter-routing-key"] = FailedEmails
    };
}
