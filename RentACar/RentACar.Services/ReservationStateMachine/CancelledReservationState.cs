using RentACar.Services.Database;
using RentACar.Services.Interfaces;

namespace RentACar.Services.ReservationStateMachine;

public class CancelledReservationState : BaseReservationState
{
    public CancelledReservationState(RentACarDbContext dbContext, IAuthenticatedUserAccessor authenticatedUser, IServiceProvider serviceProvider)
        : base(dbContext, authenticatedUser, serviceProvider)
    {
    }
}
