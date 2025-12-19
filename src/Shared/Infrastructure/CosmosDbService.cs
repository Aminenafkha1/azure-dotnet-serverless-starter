using Microsoft.Azure.Cosmos;

namespace Shared.Infrastructure;

public interface ICosmosDbService
{
    Container GetContainer(string containerName);
}

public class CosmosDbService : ICosmosDbService
{
    private readonly CosmosClient _cosmosClient;
    private readonly string _databaseName;

    public CosmosDbService(CosmosClient cosmosClient, string databaseName)
    {
        _cosmosClient = cosmosClient ?? throw new ArgumentNullException(nameof(cosmosClient));
        _databaseName = databaseName ?? throw new ArgumentNullException(nameof(databaseName));
    }

    public Container GetContainer(string containerName)
    {
        return _cosmosClient.GetContainer(_databaseName, containerName);
    }
}
