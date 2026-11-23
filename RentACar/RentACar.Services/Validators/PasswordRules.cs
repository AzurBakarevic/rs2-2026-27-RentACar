using FluentValidation;

namespace RentACar.Services.Validators;

public static class PasswordRules
{
    public const int MinLength = 8;
    public const int MaxLength = 100;

    public static IRuleBuilderOptions<T, string?> ValidPassword<T>(this IRuleBuilder<T, string?> rule)
    {
        return rule
            .NotEmpty().WithMessage("Lozinka je obavezna.")
            .Length(MinLength, MaxLength).WithMessage($"Lozinka mora imati između {MinLength} i {MaxLength} znakova.");
    }
}
