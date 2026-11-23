using FluentValidation;
using RentACar.Model.Requests;

namespace RentACar.Services.Validators;

public class UserDetailsValidator : AbstractValidator<IUserDetails>
{
    public UserDetailsValidator()
    {
        RuleFor(x => x.FirstName)
            .NotEmpty().WithMessage("Ime je obavezno.")
            .MaximumLength(50).WithMessage("Ime može imati najviše 50 znakova.");

        RuleFor(x => x.LastName)
            .NotEmpty().WithMessage("Prezime je obavezno.")
            .MaximumLength(50).WithMessage("Prezime može imati najviše 50 znakova.");

        RuleFor(x => x.Email).ValidEmail();

        RuleFor(x => x.PhoneNumber)
            .NotEmpty().WithMessage("Broj telefona je obavezan.")
            .Matches(@"^\+?[0-9][0-9 /-]{5,28}$").WithMessage("Broj telefona nije ispravnog formata.");

        RuleFor(x => x.Username)
            .NotEmpty().WithMessage("Korisničko ime je obavezno.")
            .Length(3, 50).WithMessage("Korisničko ime mora imati između 3 i 50 znakova.")
            .Matches("^[a-zA-Z0-9._-]+$").WithMessage("Korisničko ime smije sadržavati samo slova bez kvačica, brojeve, tačku, crticu i donju crtu.");

        RuleFor(x => x.DriverLicenseNumber)
            .MaximumLength(30).WithMessage("Broj vozačke dozvole može imati najviše 30 znakova.");

        RuleFor(x => x.DriverLicenseValidUntil)
            .NotNull().WithMessage("Unesite datum do kojeg važi vozačka dozvola.")
            .When(x => !string.IsNullOrWhiteSpace(x.DriverLicenseNumber));

        RuleFor(x => x.DriverLicenseNumber)
            .NotEmpty().WithMessage("Unesite broj vozačke dozvole.")
            .When(x => x.DriverLicenseValidUntil.HasValue);
    }
}
