namespace RentACar.Services.Interfaces;

public record GatewayPaymentIntent(
    string Id,
    string Status,
    long Amount,
    long AmountReceived,
    string Currency,
    string? ClientSecret,
    IReadOnlyDictionary<string, string> Metadata)
{
    public const string StatusSucceeded = "succeeded";
    public const string StatusCanceled = "canceled";
    public const string StatusProcessing = "processing";

    public bool IsSucceeded => Status == StatusSucceeded;
    public bool IsCanceled => Status == StatusCanceled;
    public bool IsProcessing => Status == StatusProcessing;
}
