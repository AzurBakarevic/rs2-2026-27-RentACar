using DotNetEnv;
using FluentValidation;
using Mapster;
using RentACar.Model.Requests;
using RentACar.Services.Implementations;
using RentACar.Services.Interfaces;
using RentACar.Services.Mapping;
using RentACar.Services.ReservationStateMachine;
using RentACar.Services.Validators;
using RentACar.WebAPI.BackgroundServices;
using RentACar.WebAPI.Extensions;
using RentACar.WebAPI.Filters;
using RentACar.WebAPI.Services;
using RentACar.WebAPI.Services.AccessManager;
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
builder.Services.AddRentACarOpenApi();
builder.Services.AddRentACarDatabase(builder.Configuration);
builder.Services.AddRentACarAuthentication(builder.Configuration);
builder.Services.AddRentACarStripe(builder.Configuration);
builder.Services.AddRentACarMessaging(builder.Configuration);

builder.Services.AddHttpContextAccessor();
builder.Services.AddMemoryCache();

// Mapster mapira svojstva istog naziva; BrandName u odgovoru se puni iz Brand.Name bez dodatne konfiguracije.
// Ono što se ne može izvesti iz naziva (npr. prosječna ocjena vozila) je u MappingConfig.
builder.Services.AddMapster();
TypeAdapterConfig.GlobalSettings.Scan(typeof(MappingConfig).Assembly);

builder.Services.AddScoped<IAuthenticatedUserAccessor, HttpAuthenticatedUserAccessor>();
builder.Services.AddScoped<ICryptoService, CryptoService>();
builder.Services.AddScoped<IAccessManager, AccessManager>();
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<IRoleService, RoleService>();
builder.Services.AddScoped<IBrandService, BrandService>();
builder.Services.AddScoped<IVehicleModelService, VehicleModelService>();
builder.Services.AddScoped<ICategoryService, CategoryService>();
builder.Services.AddScoped<IFuelTypeService, FuelTypeService>();
builder.Services.AddScoped<ITransmissionTypeService, TransmissionTypeService>();
builder.Services.AddScoped<IVehicleService, VehicleService>();
builder.Services.AddScoped<IEquipmentService, EquipmentService>();
builder.Services.AddScoped<IVehicleMaintenanceService, VehicleMaintenanceService>();
builder.Services.AddScoped<ISeasonalPriceService, SeasonalPriceService>();
builder.Services.AddScoped<IReservationService, ReservationService>();
builder.Services.AddScoped<INotificationService, NotificationService>();
builder.Services.AddScoped<ReservationCalculator>();
builder.Services.AddScoped<ReservationPaymentHandler>();
builder.Services.AddScoped<IPaymentService, PaymentService>();
builder.Services.AddScoped<IReservationJobService, ReservationJobService>();

// Istek roka za plaćanje (15 min) i podsjetnik dan prije preuzimanja, svake minute.
builder.Services.AddHostedService<ReservationJobsBackgroundService>();

// Stanja rezervacije (kao ProductStateMachine kod profesora); BaseReservationState bira stanje po statusu.
builder.Services.AddScoped<BaseReservationState>();
builder.Services.AddScoped<InitialReservationState>();
builder.Services.AddScoped<PendingReservationState>();
builder.Services.AddScoped<ConfirmedReservationState>();
builder.Services.AddScoped<CompletedReservationState>();
builder.Services.AddScoped<CancelledReservationState>();

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
builder.Services.AddScoped<IValidator<UserInsertRequest>, UserInsertValidator>();
builder.Services.AddScoped<IValidator<UserUpdateRequest>, UserUpdateValidator>();
builder.Services.AddScoped<IValidator<UserLoginRequest>, UserLoginValidator>();
builder.Services.AddScoped<IValidator<UserRegisterRequest>, UserRegisterValidator>();
builder.Services.AddScoped<IValidator<UserProfileUpdateRequest>, UserProfileUpdateValidator>();
builder.Services.AddScoped<IValidator<UserPasswordChangeRequest>, UserPasswordChangeValidator>();
builder.Services.AddScoped<IValidator<PasswordForgotRequest>, PasswordForgotValidator>();
builder.Services.AddScoped<IValidator<PasswordResetRequest>, PasswordResetValidator>();
builder.Services.AddScoped<IValidator<VehicleInsertRequest>, VehicleInsertValidator>();
builder.Services.AddScoped<IValidator<VehicleUpdateRequest>, VehicleUpdateValidator>();
builder.Services.AddScoped<IValidator<ImageUploadRequest>, ImageUploadValidator>();
builder.Services.AddScoped<IValidator<EquipmentInsertRequest>, EquipmentInsertValidator>();
builder.Services.AddScoped<IValidator<EquipmentUpdateRequest>, EquipmentUpdateValidator>();
builder.Services.AddScoped<IValidator<VehicleMaintenanceInsertRequest>, VehicleMaintenanceInsertValidator>();
builder.Services.AddScoped<IValidator<VehicleMaintenanceUpdateRequest>, VehicleMaintenanceUpdateValidator>();
builder.Services.AddScoped<IValidator<SeasonalPriceInsertRequest>, SeasonalPriceInsertValidator>();
builder.Services.AddScoped<IValidator<SeasonalPriceUpdateRequest>, SeasonalPriceUpdateValidator>();
builder.Services.AddScoped<IValidator<ReservationInsertRequest>, ReservationInsertValidator>();
builder.Services.AddScoped<IValidator<ReservationRejectRequest>, ReservationRejectValidator>();
builder.Services.AddScoped<IValidator<ReservationCancelRequest>, ReservationCancelValidator>();

var app = builder.Build();

await app.MigrateDatabaseAsync();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.MapScalarApiReference();
}

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();
