using FluentValidation;
using RentACar.Model.Requests;

namespace RentACar.Services.Validators;

// Samo da polja nisu prazna; pravila za dužinu lozinke se ovdje ne primjenjuju (testna lozinka je "test").
public class UserLoginValidator : AbstractValidator<UserLoginRequest>
{
    public UserLoginValidator()
    {
        RuleFor(x => x.Username)
            .NotEmpty().WithMessage("Korisničko ime je obavezno.");

        RuleFor(x => x.Password)
            .NotEmpty().WithMessage("Lozinka je obavezna.");
    }
}
