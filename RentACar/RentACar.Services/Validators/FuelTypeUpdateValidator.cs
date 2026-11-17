using FluentValidation;
using RentACar.Model.Requests;

namespace RentACar.Services.Validators;

public class FuelTypeUpdateValidator : AbstractValidator<FuelTypeUpdateRequest>
{
    public FuelTypeUpdateValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Naziv je obavezan.")
            .MaximumLength(50).WithMessage("Naziv može imati najviše 50 znakova.");
    }
}
