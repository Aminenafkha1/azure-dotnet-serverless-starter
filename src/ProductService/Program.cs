using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Azure.Cosmos;
using ProductService.Services;
using Shared.Infrastructure;
using Shared.Models;

var host = new HostBuilder()
    .ConfigureFunctionsWebApplication(builder =>
    {
        builder.UseMiddleware<ProductService.Middleware.JwtAuthenticationMiddleware>();
    })
    .ConfigureServices((context, services) =>
    {
        services.AddApplicationInsightsTelemetryWorkerService();
        services.ConfigureFunctionsApplicationInsights();

        // Add CORS
        services.AddCors(options =>
        {
            options.AddDefaultPolicy(policy =>
            {
                policy.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader();
            });
        });

        // Configuration
        var configuration = context.Configuration;

        // Bind settings
        var cosmosDbSettings = new CosmosDbSettings();
        configuration.GetSection("CosmosDb").Bind(cosmosDbSettings);

        var jwtSettings = new JwtSettings();
        configuration.GetSection("JwtSettings").Bind(jwtSettings);

        services.AddSingleton(cosmosDbSettings);
        services.AddSingleton(jwtSettings);

        // Cosmos DB
        services.AddSingleton<CosmosClient>(sp =>
        {
            return new CosmosClient(
                cosmosDbSettings.EndpointUrl,
                cosmosDbSettings.PrimaryKey,
                new CosmosClientOptions
                {
                    SerializerOptions = new CosmosSerializationOptions
                    {
                        PropertyNamingPolicy = CosmosPropertyNamingPolicy.CamelCase
                    }
                });
        });

        services.AddSingleton<ICosmosDbService>(sp =>
        {
            var cosmosClient = sp.GetRequiredService<CosmosClient>();
            return new CosmosDbService(cosmosClient, cosmosDbSettings.DatabaseName);
        });

        // Services
        services.AddScoped<IProductService, ProductService.Services.ProductService>();
    })
    .Build();

host.Run();
