namespace RentACar.Model.Messaging;

public static class MessageQueues
{
    public const string Emails = "rentacar.emails";

    public const string FailedEmails = "rentacar.emails.failed";

    public static IDictionary<string, object?> EmailQueueArguments => new Dictionary<string, object?>
    {
        ["x-dead-letter-exchange"] = string.Empty,
        ["x-dead-letter-routing-key"] = FailedEmails
    };
}
