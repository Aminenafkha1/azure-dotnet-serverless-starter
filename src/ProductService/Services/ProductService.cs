using Microsoft.Azure.Cosmos;
using ProductService.Models;
using Shared.Infrastructure;

namespace ProductService.Services;

public interface IProductService
{
    Task<Product> CreateProductAsync(CreateProductRequest request, string userId);
    Task<IEnumerable<Product>> GetProductsAsync(int page = 1, int pageSize = 10);
    Task<Product?> GetProductByIdAsync(string id);
}

public class ProductService : IProductService
{
    private readonly Container _productContainer;

    public ProductService(ICosmosDbService cosmosDbService)
    {
        _productContainer = cosmosDbService.GetContainer("Products");
    }

    public async Task<Product> CreateProductAsync(CreateProductRequest request, string userId)
    {
        var product = new Product
        {
            Name = request.Name,
            Description = request.Description,
            Price = request.Price,
            Category = request.Category,
            Stock = request.Stock,
            CreatedBy = userId
        };

        var response = await _productContainer.CreateItemAsync(product, new PartitionKey(product.Id));
        return response.Resource;
    }

    public async Task<IEnumerable<Product>> GetProductsAsync(int page = 1, int pageSize = 10)
    {
        var query = new QueryDefinition(
            "SELECT * FROM c WHERE c.isActive = true ORDER BY c.createdAt DESC OFFSET @offset LIMIT @limit")
            .WithParameter("@offset", (page - 1) * pageSize)
            .WithParameter("@limit", pageSize);

        var iterator = _productContainer.GetItemQueryIterator<Product>(query);
        var products = new List<Product>();

        while (iterator.HasMoreResults)
        {
            var response = await iterator.ReadNextAsync();
            products.AddRange(response);
        }

        return products;
    }

    public async Task<Product?> GetProductByIdAsync(string id)
    {
        try
        {
            var response = await _productContainer.ReadItemAsync<Product>(id, new PartitionKey(id));
            return response.Resource;
        }
        catch (CosmosException ex) when (ex.StatusCode == System.Net.HttpStatusCode.NotFound)
        {
            return null;
        }
    }
}
