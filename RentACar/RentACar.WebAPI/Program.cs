using DotNetEnv;
using FluentValidation;
using Mapster;
using QuestPDF.Infrastructure;
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

Env.NoClobber().TraversePath().Load();

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers(options =>
    {
        options.Filters.Add<ExceptionFilter>();
        options.SuppressImplicitRequiredAttributeForNonNullableReferenceTypes = true;
    })
    .ConfigureApiBehaviorOptions(options => options.InvalidModelStateResponseFactory = ExceptionFilter.InvalidModelState);
builder.Services.AddRentACarOpenApi();
builder.Services.AddRentACarDatabase(builder.Configuration);
builder.Services.AddRentACarAuthentication(builder.Configuration);
builder.Services.AddRentACarStripe(builder.Configuration);
builder.Services.AddRentACarMessaging(builder.Configuration);

builder.Services.AddHttpContextAccessor();
builder.Services.AddMemoryCache();

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
builder.Services.AddScoped<IReviewService, ReviewService>();
builder.Services.AddScoped<IDashboardService, DashboardService>();
builder.Services.AddScoped<IReportService, ReportService>();

QuestPDF.Settings.License = LicenseType.Community;

builder.Services.AddHostedService<ReservationJobsBackgroundService>();

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
builder.Services.AddScoped<IValidator<ReviewInsertRequest>, ReviewInsertValidator>();
builder.Services.AddScoped<IValidator<ReportPeriodRequest>, ReportPeriodValidator>();

var app = builder.Build();

await app.MigrateDatabaseAsync();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.MapScalarApiReference();
}

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();
