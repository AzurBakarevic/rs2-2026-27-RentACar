namespace RentACar.Services.Interfaces;

// Povrat novca kako ga vraća servis za plaćanje (Stripe Refund); status: pending, succeeded, failed, canceled, requires_action.
public record GatewayRefund(string Id, string Status, long Amount);
