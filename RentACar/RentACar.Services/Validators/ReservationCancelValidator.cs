using FluentValidation;
using RentACar.Model.Constants;
using RentACar.Model.Requests;
using RentACar.Services.Interfaces;

namespace RentACar.Services.Validators;

public class ReservationCancelValidator : AbstractValidator<ReservationCancelRequest>
{
    public ReservationCancelValidator(IAuthenticatedUserAccessor authenticatedUser)
    {
        // Prijava: unos razloga je obavezan kad otkazuje administrator; korisnik ga ne mora navesti.
        RuleFor(x => x.Reason)
            .NotEmpty().WithMessage("Razlog otkazivanja je obavezan.")
            .When(_ => authenticatedUser.IsInRole(RoleNames.Administrator));

        RuleFor(x => x.Reason)
            .MaximumLength(ReservationReasonRules.MaxLength)
            .WithMessage($"Razlog može imati najviše {ReservationReasonRules.MaxLength} znakova.");
    }
}
