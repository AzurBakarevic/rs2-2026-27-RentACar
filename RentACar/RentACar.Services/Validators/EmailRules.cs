using FluentValidation;

namespace RentACar.Services.Validators;

public static class EmailRules
{
    public const int MaxLength = 100;

    // Ista pravila za e-mail u svim zahtjevima (upute 4: format e-maila).
    public static IRuleBuilderOptions<T, string?> ValidEmail<T>(this IRuleBuilder<T, string?> rule)
    {
        return rule
            .NotEmpty().WithMessage("E-mail je obavezan.")
            .EmailAddress().WithMessage("E-mail nije ispravnog formata.")
            .MaximumLength(MaxLength).WithMessage($"E-mail može imati najviše {MaxLength} znakova.");
    }
}
