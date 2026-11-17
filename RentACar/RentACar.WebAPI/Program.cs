using DotNetEnv;
using RentACar.WebAPI.Extensions;
using Scalar.AspNetCore;

// Učitava .env (traži ga od trenutnog foldera naviše); varijable koje su već postavljene (npr. iz Dockera) se ne mijenjaju.
Env.NoClobber().TraversePath().Load();

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services.AddControllers();
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();
builder.Services.AddRentACarDatabase(builder.Configuration);

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
