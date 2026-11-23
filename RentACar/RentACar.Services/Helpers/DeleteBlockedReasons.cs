namespace RentACar.Services.Helpers;

public static class DeleteBlockedReasons
{
    public const string BrandHasModels = "Marka se ne može obrisati jer ima modele.";
    public const string VehicleModelInUse = "Model se ne može obrisati jer ga koriste vozila.";
    public const string CategoryInUse = "Kategorija se ne može obrisati jer je koriste vozila.";
    public const string FuelTypeInUse = "Vrsta goriva se ne može obrisati jer je koriste vozila.";
    public const string TransmissionTypeInUse = "Vrsta mjenjača se ne može obrisati jer je koriste vozila.";
    public const string VehicleHasReservations = "Vozilo se ne može obrisati jer ima rezervacije. Umjesto brisanja ga deaktivirajte.";
    public const string EquipmentInUse = "Oprema se ne može obrisati jer je korištena u rezervacijama. Umjesto brisanja je deaktivirajte.";
}
