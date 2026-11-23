using FluentValidation;
using RentACar.Model.Requests;

namespace RentACar.Services.Validators;

public class ReviewInsertValidator : AbstractValidator<ReviewInsertRequest>
{
    public const int MinRating = 1;
    public const int MaxRating = 5;

    public const int MaxCommentLength = 1000;

    public ReviewInsertValidator()
    {
        RuleFor(x => x.ReservationId)
            .GreaterThan(0).WithMessage("Odaberite rezervaciju.");

        RuleFor(x => x.Rating)
            .InclusiveBetween(MinRating, MaxRating).WithMessage($"Ocjena mora biti od {MinRating} do {MaxRating}.");

        RuleFor(x => x.Comment)
            .MaximumLength(MaxCommentLength).WithMessage($"Komentar može imati najviše {MaxCommentLength} znakova.");
    }
}
