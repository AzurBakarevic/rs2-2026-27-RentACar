namespace RentACar.Model.Responses;

public class VehicleResponse
{
    public int Id { get; set; }
    public string RegistrationNumber { get; set; } = string.Empty;
    public int ProductionYear { get; set; }
    public int SeatCount { get; set; }
    public string? Description { get; set; }
    public decimal PricePerDay { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public bool HasImage { get; set; }

    public int BrandId { get; set; }
    public string BrandName { get; set; } = string.Empty;

    public int VehicleModelId { get; set; }
    public string VehicleModelName { get; set; } = string.Empty;

    public int CategoryId { get; set; }
    public string CategoryName { get; set; } = string.Empty;

    public int FuelTypeId { get; set; }
    public string FuelTypeName { get; set; } = string.Empty;

    public int TransmissionTypeId { get; set; }
    public string TransmissionTypeName { get; set; } = string.Empty;

    public double? AverageRating { get; set; }
    public int ReviewCount { get; set; }

    public string? DeleteBlockedReason { get; set; }
}
