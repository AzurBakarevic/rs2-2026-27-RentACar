namespace RentACar.Services.Interfaces;

// Prijavljeni korisnik iz JWT tokena trenutnog zahtjeva. Implementacija je u WebAPI-ju (preko IHttpContextAccessor),
// pa servisi ne parsiraju token sami (upute, poglavlje 3).
public interface IAuthenticatedUserAccessor
{
    int? GetUserId();
    bool IsInRole(string role);
}
