using Microsoft.OpenApi;

namespace RentACar.WebAPI.Extensions;

public static class OpenApiExtensions
{
    private const string BearerSchemeName = "Bearer";

    public static IServiceCollection AddRentACarOpenApi(this IServiceCollection services)
    {
        services.AddOpenApi(options =>
        {
            options.AddDocumentTransformer((document, context, cancellationToken) =>
            {
                document.Components ??= new OpenApiComponents();
                document.Components.SecuritySchemes ??= new Dictionary<string, IOpenApiSecurityScheme>();
                document.Components.SecuritySchemes[BearerSchemeName] = new OpenApiSecurityScheme
                {
                    Type = SecuritySchemeType.Http,
                    Scheme = "bearer",
                    BearerFormat = "JWT",
                    Description = "Token iz POST /Access/Login (bez prefiksa \"Bearer\")."
                };

                document.Security ??= [];
                document.Security.Add(new OpenApiSecurityRequirement
                {
                    [new OpenApiSecuritySchemeReference(BearerSchemeName, document)] = []
                });

                return Task.CompletedTask;
            });
        });

        return services;
    }
}
