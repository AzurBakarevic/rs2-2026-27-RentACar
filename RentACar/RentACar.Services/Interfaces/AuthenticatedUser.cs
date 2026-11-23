namespace RentACar.Services.Interfaces;

public record AuthenticatedUser(int Id, string Username, string Role, int TokenVersion);
