using DotNetEnv;
using FluentValidation;
using Mapster;
using RentACar.Model.Requests;
using RentACar.Services.Implementations;
using RentACar.Services.Interfaces;
using RentACar.Services.Validators;
using RentACar.WebAPI.Extensions;
using RentACar.WebAPI.Filters;
using Scalar.AspNetCore;

// Učitava .env (traži ga od trenutnog foldera naviše); varijable koje su već postavljene (npr. iz Dockera) se ne mijenjaju.
Env.NoClobber().TraversePath().Load();

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services.AddControllers(options =>
    {
        options.Filters.Add<ExceptionFilter>();
        // Obavezna polja provjerava FluentValidation (poruke na bosanskom), a ne ugrađena provjera ASP.NET-a.
        options.SuppressImplicitRequiredAttributeForNonNullableReferenceTypes = true;
    })
    // Neispravan JSON ili pogrešan tip vrijednosti: isti oblik greške kao iz ExceptionFilter-a.
    .ConfigureApiBehaviorOptions(options => options.InvalidModelStateResponseFactory = ExceptionFilter.InvalidModelState);
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();
builder.Services.AddRentACarDatabase(builder.Configuration);

// Mapster mapira svojstva istog naziva; BrandName u odgovoru se puni iz Brand.Name bez dodatne konfiguracije.
builder.Services.AddMapster();

builder.Services.AddScoped<IBrandService, BrandService>();
builder.Services.AddScoped<IVehicleModelService, VehicleModelService>();
builder.Services.AddScoped<ICategoryService, CategoryService>();
builder.Services.AddScoped<IFuelTypeService, FuelTypeService>();
builder.Services.AddScoped<ITransmissionTypeService, TransmissionTypeService>();

builder.Services.AddScoped<IValidator<BrandInsertRequest>, BrandInsertValidator>();
builder.Services.AddScoped<IValidator<BrandUpdateRequest>, BrandUpdateValidator>();
builder.Services.AddScoped<IValidator<VehicleModelInsertRequest>, VehicleModelInsertValidator>();
builder.Services.AddScoped<IValidator<VehicleModelUpdateRequest>, VehicleModelUpdateValidator>();
builder.Services.AddScoped<IValidator<CategoryInsertRequest>, CategoryInsertValidator>();
builder.Services.AddScoped<IValidator<CategoryUpdateRequest>, CategoryUpdateValidator>();
builder.Services.AddScoped<IValidator<FuelTypeInsertRequest>, FuelTypeInsertValidator>();
builder.Services.AddScoped<IValidator<FuelTypeUpdateRequest>, FuelTypeUpdateValidator>();
builder.Services.AddScoped<IValidator<TransmissionTypeInsertRequest>, TransmissionTypeInsertValidator>();
builder.Services.AddScoped<IValidator<TransmissionTypeUpdateRequest>, TransmissionTypeUpdateValidator>();

var app = builder.Build();

app.MigrateDatabase();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.MapScalarApiReference();
}

app.UseAuthorization();

app.MapControllers();

app.Run();
