using FluentValidation;
using RentACar.Model.Requests;

namespace RentACar.Services.Validators;

public class FuelTypeInsertValidator : AbstractValidator<FuelTypeInsertRequest>
{
    public FuelTypeInsertValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Naziv je obavezan.")
            .MaximumLength(50).WithMessage("Naziv može imati najviše 50 znakova.");
    }
}
