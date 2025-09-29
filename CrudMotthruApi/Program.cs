using Microsoft.EntityFrameworkCore;
using CrudMotthruApi;

var builder = WebApplication.CreateBuilder(args);

builder.WebHost.UseUrls("http://*:8080");

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.Services.AddDbContext<AppDbContext>(options => 
    options.UseNpgsql(builder.Configuration.GetConnectionString("Postgres")));

var app = builder.Build();

try
{
    using var scope = app.Services.CreateScope();
    var dbContext = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    dbContext.Database.Migrate();
    Console.WriteLine("--> Migrations aplicadas com sucesso.");
}
catch (Exception ex)
{
    Console.WriteLine($"--> Ocorreu um erro ao aplicar as migrations: {ex.Message}");
}

app.UseSwagger();
app.UseSwaggerUI();

app.MapGet("/motos", async (AppDbContext context) => 
    await context.Motos.ToListAsync());

app.MapGet("/motos/{id}", async (int id, AppDbContext context) => 
    await context.Motos.FindAsync(id) is Moto moto ? Results.Ok(moto) : Results.NotFound());

app.MapPost("/motos", async (Moto moto, AppDbContext context) =>
{
    context.Motos.Add(moto);
    await context.SaveChangesAsync();
    return Results.Created($"/motos/{moto.Id}", moto);
});

app.MapPut("/motos/{id}", async (int id, Moto inputMoto, AppDbContext context) =>
{
    var moto = await context.Motos.FindAsync(id);
    if (moto is null) return Results.NotFound();
    
    moto.Placa = inputMoto.Placa;
    moto.Chassi = inputMoto.Chassi;
    moto.NumMotor = inputMoto.NumMotor;
    moto.IdModelo = inputMoto.IdModelo;
    moto.IdPatio = inputMoto.IdPatio;

    await context.SaveChangesAsync();
    return Results.NoContent();
});

app.MapDelete("/motos/{id}", async (int id, AppDbContext context) =>
{
    if (await context.Motos.FindAsync(id) is Moto moto)
    {
        context.Motos.Remove(moto);
        await context.SaveChangesAsync();
        return Results.Ok(moto);
    }
    return Results.NotFound();
});

app.Run();
