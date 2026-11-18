namespace RentACar.Services.Validators;

public static class ReservationReasonRules
{
    // Razlog ulazi i u tekst notifikacije (najviše 500 znakova), pa mora ostati mjesta za ostatak poruke.
    public const int MaxLength = 300;
}
