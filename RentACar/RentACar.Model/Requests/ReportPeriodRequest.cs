namespace RentACar.Model.Requests;

public class ReportPeriodRequest
{
    public DateOnly? From { get; set; }
    public DateOnly? To { get; set; }
}
