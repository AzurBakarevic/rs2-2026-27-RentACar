using RentACar.Services.Database;
using RentACar.Services.Interfaces;

namespace RentACar.Services.ReservationStateMachine;

// Završena: završno stanje, nijedna akcija nije dozvoljena (prijava). Korisnik iz nje ostavlja recenziju.
public class CompletedReservationState : BaseReservationState
{
    public CompletedReservationState(RentACarDbContext dbContext, IAuthenticatedUserAccessor authenticatedUser, IServiceProvider serviceProvider)
        : base(dbContext, authenticatedUser, serviceProvider)
    {
    }
}
