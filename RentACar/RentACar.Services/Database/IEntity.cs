namespace RentACar.Services.Database;

// Entitet s cjelobrojnim ključem Id; treba generičkim servisima da mogu tražiti po Id-u.
public interface IEntity
{
    int Id { get; }
}
