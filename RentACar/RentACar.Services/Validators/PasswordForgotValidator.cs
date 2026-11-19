using FluentValidation;
using RentACar.Model.Requests;

namespace RentACar.Services.Validators;

public class PasswordForgotValidator : AbstractValidator<PasswordForgotRequest>
{
    public PasswordForgotValidator()
    {
        RuleFor(x => x.Email).ValidEmail();
    }
}
