var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services.AddControllers();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// Configure the HTTP request pipeline.

// Since our K8s ingress has path of /web-api add these two
// lines to prepend all our routed with /web-api
// Run locally you, can hit / and /web-api
// See https://docs.microsoft.com/en-us/aspnet/core/fundamentals/routing?view=aspnetcore-6.0
app.UsePathBase("/web-api");
app.UseRouting();

// let's always show Swagger, so comment this out
//if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// let's assume TLS termination before K8s
// app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

// add root and health checks
app.MapGet("/", () => "dotnet-webapi. Check /web-api/health/live and /web-api/health/ready");
app.MapGet("/health/ready", () => "ready");
app.MapGet("/health/live", () => "live");

app.Run();
