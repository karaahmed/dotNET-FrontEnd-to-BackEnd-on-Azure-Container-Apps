using Dapr.Client;
using Microsoft.Extensions.Caching.Memory;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddMemoryCache(); // we'll use cache to simulate storage
builder.Services.AddApplicationMonitoring();
builder.Services.AddDaprClient();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.MapGet("/inventory/{productId}", async (string productId, DaprClient daprClient ) =>
{
    var memCacheKey = $"{productId}-inventory";
    
    int inventoryValue = await daprClient.GetStateAsync<int>("statestore", memCacheKey);
    if (inventoryValue == 0)
    {

        inventoryValue = new Random().Next(1, 100);
        await daprClient.SaveStateAsync("statestore", memCacheKey, inventoryValue);
    }

    return Results.Ok(inventoryValue);
})
.Produces<int>(StatusCodes.Status200OK)
.WithName("GetInventoryCount");

app.Run();