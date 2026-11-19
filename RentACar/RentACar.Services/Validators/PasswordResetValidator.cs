using FluentValidation;
using RentACar.Model.Requests;
using RentACar.Services.Helpers;

namespace RentACar.Services.Validators;

public class PasswordResetValidator : AbstractValidator<PasswordResetRequest>
{
    public PasswordResetValidator()
    {
        RuleFor(x => x.Email).ValidEmail();

        RuleFor(x => x.Code)
            .NotEmpty().WithMessage("Unesite kod iz e-maila.")
            .Matches($"^[0-9]{{{PasswordResetRules.CodeLength}}}$")
            .WithMessage($"Kod mora imati {PasswordResetRules.CodeLength} cifara.");

        RuleFor(x => x.NewPassword).ValidPassword();

        RuleFor(x => x.NewPasswordConfirm)
            .Equal(x => x.NewPassword).WithMessage("Lozinke se ne podudaraju.");
    }
}
