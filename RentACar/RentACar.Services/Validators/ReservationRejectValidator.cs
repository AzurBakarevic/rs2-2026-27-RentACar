using FluentValidation;
using RentACar.Model.Requests;

namespace RentACar.Services.Validators;

public class ReservationRejectValidator : AbstractValidator<ReservationRejectRequest>
{
    public ReservationRejectValidator()
    {
        RuleFor(x => x.Reason)
            .NotEmpty().WithMessage("Razlog odbijanja je obavezan.")
            .MaximumLength(ReservationReasonRules.MaxLength)
            .WithMessage($"Razlog može imati najviše {ReservationReasonRules.MaxLength} znakova.");
    }
}
