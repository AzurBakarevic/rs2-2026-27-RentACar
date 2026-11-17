using FluentValidation;
using RentACar.Model.Requests;

namespace RentACar.Services.Validators;

public class UserPasswordChangeValidator : AbstractValidator<UserPasswordChangeRequest>
{
    public UserPasswordChangeValidator()
    {
        RuleFor(x => x.OldPassword)
            .NotEmpty().WithMessage("Unesite trenutnu lozinku.");

        RuleFor(x => x.NewPassword).ValidPassword();

        RuleFor(x => x.NewPasswordConfirm)
            .Equal(x => x.NewPassword).WithMessage("Lozinke se ne podudaraju.");
    }
}
