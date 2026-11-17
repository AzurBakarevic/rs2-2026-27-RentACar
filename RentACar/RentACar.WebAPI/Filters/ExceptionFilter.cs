using System.Text.Encodings.Web;
using System.Text.Json;
using FluentValidation;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using RentACar.Model.Exceptions;

namespace RentACar.WebAPI.Filters;

// Pretvara izuzetke iz kontrolera i servisa u HTTP odgovor. Svaka greška ima isti oblik (kao kod profesora):
// { "message": "prva poruka", "errors": { "Name": ["..."] } } ili { ..., "errors": { "clientError": ["..."] } }
public class ExceptionFilter : ExceptionFilterAttribute
{
    private const string ClientErrorKey = "clientError";
    private const string ServerErrorKey = "serverError";

    // Brojevi grešaka SQL Servera: dupla vrijednost u unique indeksu i kršenje FK veze.
    private const int SqlUniqueIndexViolation = 2601;
    private const int SqlUniqueConstraintViolation = 2627;
    private const int SqlForeignKeyViolation = 547;

    // Za odgovore koji se pišu direktno (401/403 iz JWT provjere): č, ć, š, ž, đ se ne escapuju, kao u ObjectResult-u.
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web)
    {
        Encoder = JavaScriptEncoder.UnsafeRelaxedJsonEscaping
    };

    private readonly ILogger<ExceptionFilter> _logger;

    public ExceptionFilter(ILogger<ExceptionFilter> logger)
    {
        _logger = logger;
    }

    public override void OnException(ExceptionContext context)
    {
        var request = context.HttpContext.Request;
        int status;

        switch (context.Exception)
        {
            case ValidationException validationException:
                foreach (var error in validationException.Errors)
                {
                    context.ModelState.AddModelError(error.PropertyName ?? string.Empty, error.ErrorMessage);
                }
                status = StatusCodes.Status400BadRequest;
                _logger.LogWarning("Validation failed on {Method} {Path}.", request.Method, request.Path);
                break;

            case ClientException clientException:
                context.ModelState.AddModelError(ClientErrorKey, clientException.Message);
                status = StatusCodes.Status400BadRequest;
                _logger.LogWarning("Client rule on {Method} {Path}: {Message}", request.Method, request.Path, clientException.Message);
                break;

            case KeyNotFoundException:
                context.ModelState.AddModelError(ClientErrorKey, "Traženi zapis nije pronađen.");
                status = StatusCodes.Status404NotFound;
                _logger.LogInformation("{Message} ({Method} {Path})", context.Exception.Message, request.Method, request.Path);
                break;

            case UnauthorizedAccessException:
                context.ModelState.AddModelError(ClientErrorKey, "Niste prijavljeni.");
                status = StatusCodes.Status401Unauthorized;
                _logger.LogWarning("Unauthorized access on {Method} {Path}.", request.Method, request.Path);
                break;

            // Rezerva ako dva zahtjeva u isto vrijeme prođu provjeru u servisu, pa baza odbije drugi.
            case DbUpdateException { InnerException: SqlException sql }
                when sql.Number is SqlUniqueIndexViolation or SqlUniqueConstraintViolation:
                context.ModelState.AddModelError(ClientErrorKey, "Zapis s ovim podacima već postoji.");
                status = StatusCodes.Status409Conflict;
                _logger.LogWarning(context.Exception, "Unique constraint violated on {Method} {Path}.", request.Method, request.Path);
                break;

            case DbUpdateException { InnerException: SqlException { Number: SqlForeignKeyViolation } }:
                context.ModelState.AddModelError(ClientErrorKey, "Operacija nije dozvoljena jer je zapis povezan s drugim podacima.");
                status = StatusCodes.Status409Conflict;
                _logger.LogWarning(context.Exception, "Foreign key violated on {Method} {Path}.", request.Method, request.Path);
                break;

            default:
                context.ModelState.AddModelError(ServerErrorKey, "Došlo je do greške na serveru. Pokušajte ponovo.");
                status = StatusCodes.Status500InternalServerError;
                _logger.LogError(context.Exception, "Unhandled exception on {Method} {Path}.", request.Method, request.Path);
                break;
        }

        context.Result = CreateResult(status, context.ModelState
            .Where(x => x.Value is { Errors.Count: > 0 })
            .ToDictionary(x => x.Key, x => x.Value!.Errors.Select(e => e.ErrorMessage).ToList()));
        context.ExceptionHandled = true;
    }

    // Za neispravan zahtjev koji ne dođe do akcije (loš JSON, pogrešan tip vrijednosti): isti oblik greške,
    // bez tehničkih poruka parsera, koje se samo zapisuju u log.
    public static IActionResult InvalidModelState(ActionContext context)
    {
        var request = context.HttpContext.Request;
        var logger = context.HttpContext.RequestServices.GetRequiredService<ILogger<ExceptionFilter>>();
        logger.LogWarning("Invalid request on {Method} {Path}: {Errors}", request.Method, request.Path,
            string.Join(" | ", context.ModelState.SelectMany(x => x.Value!.Errors.Select(e => $"{x.Key}: {e.ErrorMessage}"))));

        return CreateResult(StatusCodes.Status400BadRequest, new Dictionary<string, List<string>>
        {
            [ClientErrorKey] = ["Zahtjev nije ispravnog formata."]
        });
    }

    // Isti oblik greške za odgovore koji ne prolaze kroz MVC (npr. 401 i 403 iz JWT autentifikacije).
    public static Task WriteErrorAsync(HttpResponse response, int status, string message)
    {
        response.StatusCode = status;
        var errors = new Dictionary<string, List<string>> { [ClientErrorKey] = [message] };

        return response.WriteAsJsonAsync(new { message, errors }, JsonOptions);
    }

    // ObjectResult (a ne JsonResult) ide kroz isti JSON formatter kao uspješni odgovori, pa se č, ć, š, ž, đ ne escapuju.
    private static ObjectResult CreateResult(int status, Dictionary<string, List<string>> errors)
    {
        var message = errors.Values.SelectMany(x => x).FirstOrDefault() ?? "Zahtjev nije moguće obraditi.";

        return new ObjectResult(new { message, errors }) { StatusCode = status };
    }
}
