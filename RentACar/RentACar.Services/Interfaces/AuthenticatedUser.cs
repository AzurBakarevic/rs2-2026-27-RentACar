namespace RentACar.Services.Interfaces;

// Rezultat uspješne provjere korisničkog imena i lozinke; iz njega AccessManager pravi token.
public record AuthenticatedUser(int Id, string Username, string Role, int TokenVersion);
