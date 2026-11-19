using DotNetEnv;
using RentACar.Model.Messaging;
using RentACar.Worker;

// Učitava .env kad se Worker pokreće lokalno (traži ga od trenutnog foldera naviše); varijable koje su već
// postavljene (u Dockeru ih postavlja docker-compose) se ne mijenjaju. Isto kao u API-ju.
Env.NoClobber().TraversePath().Load();

var builder = Host.CreateApplicationBuilder(args);

var rabbitMqSection = builder.Configuration.GetSection(RabbitMqSettings.SectionName);
(rabbitMqSection.Get<RabbitMqSettings>() ?? new RabbitMqSettings()).Validate();
builder.Services.Configure<RabbitMqSettings>(rabbitMqSection);

var smtpSection = builder.Configuration.GetSection(SmtpSettings.SectionName);
(smtpSection.Get<SmtpSettings>() ?? new SmtpSettings()).Validate();
builder.Services.Configure<SmtpSettings>(smtpSection);

builder.Services.AddSingleton<EmailSender>();
builder.Services.AddHostedService<EmailQueueConsumer>();

var host = builder.Build();
host.Run();
