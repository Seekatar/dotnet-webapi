using static System.Console;

WriteLine("Environment");

var env = Environment.GetEnvironmentVariables();
foreach ( var e in env.Keys)
{
    WriteLine($"   {e} => '{env[e]}'");
}
var builder = WebApplication.CreateBuilder(new WebApplicationOptions {
    Args = args,
    // no access denied to path WebRootPath = "/web-api",
    // must exist ContentRootPath = "/web-api2"
});

// Add services to the container.

builder.Services.AddControllers();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

WebApplication app = builder.Build();

// adding these two fixed base-path issue
// now can hit on / and /web-api locally
app.UsePathBase("/web-api");
app.UseRouting();

// let's always show Swagger
//if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// let's avoid Https issues for now
// app.UseHttpsRedirection();

// app.UseAuthorization();

app.MapControllers();

app.MapGet("/", () => "dotnet-webapi. Check /health/live and /health/ready" );
app.MapGet("/health/ready", () => "ready" );
app.MapGet("/health/live", () => "live" );

app.Run();
