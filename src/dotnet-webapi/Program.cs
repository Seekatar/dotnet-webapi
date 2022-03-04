using static System.Console;

WriteLine("Environment");

var env = Environment.GetEnvironmentVariables();
foreach ( var e in env.Keys)
{
    WriteLine($"   {e} => '{env[e]}'");
}
var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services.AddControllers();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// Configure the HTTP request pipeline.
//if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// app.UseHttpsRedirection();

// app.UseAuthorization();

app.MapControllers();

app.MapGet("/", () => "dotnet-webapi. Check /health/live and /health/ready" );
app.MapGet("/health/ready", () => "ready" );
app.MapGet("/health/live", () => "live" );

app.Run();
