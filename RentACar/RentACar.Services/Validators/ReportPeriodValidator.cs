using FluentValidation;
using RentACar.Model.Requests;

namespace RentACar.Services.Validators;

public class ReportPeriodValidator : AbstractValidator<ReportPeriodRequest>
{
    // Izvještaj čita sve rezervacije iz perioda, pa period ima gornju granicu (godina dana, i prestupna).
    public const int MaxPeriodDays = 366;

    public ReportPeriodValidator()
    {
        RuleFor(x => x.From)
            .NotNull().WithMessage("Odaberite datum od.");

        RuleFor(x => x.To)
            .NotNull().WithMessage("Odaberite datum do.");

        RuleFor(x => x.To)
            .Cascade(CascadeMode.Stop)
            .Must((request, to) => to >= request.From).WithMessage("Datum do ne može biti prije datuma od.")
            .Must((request, to) => to!.Value.DayNumber - request.From!.Value.DayNumber < MaxPeriodDays)
            .WithMessage("Izvještaj se može kreirati za period od najviše godinu dana.")
            .When(x => x.From.HasValue && x.To.HasValue);
    }
}
