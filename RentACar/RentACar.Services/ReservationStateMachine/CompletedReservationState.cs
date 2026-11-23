using RentACar.Model.Constants;
using RentACar.Model.Responses;
using RentACar.Services.Database;
using RentACar.Services.Interfaces;

namespace RentACar.Services.ReservationStateMachine;

public class CompletedReservationState : BaseReservationState
{
    public CompletedReservationState(RentACarDbContext dbContext, IAuthenticatedUserAccessor authenticatedUser, IServiceProvider serviceProvider)
        : base(dbContext, authenticatedUser, serviceProvider)
    {
    }

    public override List<string> GetAllowedActions(ReservationResponse reservation)
        => !IsAdministrator && !reservation.HasReview ? [ReservationActions.Review] : [];
}
