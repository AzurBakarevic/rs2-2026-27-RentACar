using FluentValidation;
using RentACar.Model.Requests;

namespace RentACar.Services.Validators;

public class SeasonalPriceInsertValidator : AbstractValidator<SeasonalPriceInsertRequest>
{
    public SeasonalPriceInsertValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Naziv je obavezan.")
            .MaximumLength(100).WithMessage("Naziv može imati najviše 100 znakova.");

        RuleFor(x => x.StartDate)
            .NotEmpty().WithMessage("Datum početka je obavezan.");

        RuleFor(x => x.EndDate)
            .NotEmpty().WithMessage("Datum završetka je obavezan.")
            .GreaterThanOrEqualTo(x => x.StartDate).WithMessage("Datum završetka ne može biti prije datuma početka.");

        RuleFor(x => x.IncreasePercentage)
            .GreaterThan(0).WithMessage("Uvećanje cijene mora biti veće od 0 %.")
            .LessThanOrEqualTo(100).WithMessage("Uvećanje cijene može biti najviše 100 %.")
            .PrecisionScale(5, 2, true).WithMessage("Uvećanje cijene može imati najviše dvije decimale.");
    }
}
