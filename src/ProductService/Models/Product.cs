using Newtonsoft.Json;

namespace ProductService.Models;

public class Product
{
    [JsonProperty("id")]
    public string Id { get; set; } = Guid.NewGuid().ToString();

    [JsonProperty("name")]
    public string Name { get; set; } = string.Empty;

    [JsonProperty("description")]
    public string? Description { get; set; }

    [JsonProperty("price")]
    public decimal Price { get; set; }

    [JsonProperty("category")]
    public string? Category { get; set; }

    [JsonProperty("stock")]
    public int Stock { get; set; }

    [JsonProperty("isActive")]
    public bool IsActive { get; set; } = true;

    [JsonProperty("createdBy")]
    public string CreatedBy { get; set; } = string.Empty;

    [JsonProperty("createdAt")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [JsonProperty("updatedAt")]
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
