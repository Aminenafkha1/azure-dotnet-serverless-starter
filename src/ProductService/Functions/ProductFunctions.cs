using System.Net;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using System.Text.Json;
using ProductService.Models;
using ProductService.Services;
using Shared.Models;
using System.ComponentModel.DataAnnotations;

namespace ProductService.Functions;

public class ProductFunctions
{
    private readonly ILogger<ProductFunctions> _logger;
    private readonly IProductService _productService;

    public ProductFunctions(ILogger<ProductFunctions> logger, IProductService productService)
    {
        _logger = logger;
        _productService = productService;
    }

    [Function("CreateProduct")]
    public async Task<HttpResponseData> CreateProduct(
        [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "products")] HttpRequestData req,
        FunctionContext context)
    {
        _logger.LogInformation("Processing create product request");

        // Check if authentication failed
        if (context.Items.TryGetValue("AuthResult", out var authResult) && authResult is HttpResponseData authResponse)
        {
            return authResponse;
        }

        try
        {
            var userId = context.Items["UserId"] as string;
            if (string.IsNullOrEmpty(userId))
            {
                var unauthorizedResponse = req.CreateResponse(HttpStatusCode.Unauthorized);
                await unauthorizedResponse.WriteAsJsonAsync(
                    ApiResponse<object>.ErrorResponse("User not authenticated"));
                return unauthorizedResponse;
            }

            var requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            var request = JsonSerializer.Deserialize<CreateProductRequest>(requestBody, new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            });

            if (request == null)
            {
                var badRequestResponse = req.CreateResponse(HttpStatusCode.BadRequest);
                await badRequestResponse.WriteAsJsonAsync(
                    ApiResponse<object>.ErrorResponse("Invalid request body"));
                return badRequestResponse;
            }

            // Validate request
            var validationResults = new List<ValidationResult>();
            var validationContext = new ValidationContext(request);
            if (!Validator.TryValidateObject(request, validationContext, validationResults, true))
            {
                var errors = validationResults.Select(v => v.ErrorMessage ?? "Validation error").ToList();
                var validationResponse = req.CreateResponse(HttpStatusCode.BadRequest);
                await validationResponse.WriteAsJsonAsync(
                    ApiResponse<object>.ErrorResponse("Validation failed", errors));
                return validationResponse;
            }

            var product = await _productService.CreateProductAsync(request, userId);

            var response = req.CreateResponse(HttpStatusCode.Created);
            await response.WriteAsJsonAsync(ApiResponse<ProductResponse>.SuccessResponse(
                MapToProductResponse(product),
                "Product created successfully"));
            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating product");
            var errorResponse = req.CreateResponse(HttpStatusCode.InternalServerError);
            await errorResponse.WriteAsJsonAsync(
                ApiResponse<object>.ErrorResponse("An error occurred while creating the product"));
            return errorResponse;
        }
    }

    [Function("GetProducts")]
    public async Task<HttpResponseData> GetProducts(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "products")] HttpRequestData req,
        FunctionContext context)
    {
        _logger.LogInformation("Processing get products request");

        // Check if authentication failed
        if (context.Items.TryGetValue("AuthResult", out var authResult) && authResult is HttpResponseData authResponse)
        {
            return authResponse;
        }

        try
        {
            var query = System.Web.HttpUtility.ParseQueryString(req.Url.Query);
            var page = int.TryParse(query["page"], out var p) ? p : 1;
            var pageSize = int.TryParse(query["pageSize"], out var ps) ? ps : 10;

            if (page < 1) page = 1;
            if (pageSize < 1 || pageSize > 100) pageSize = 10;

            var products = await _productService.GetProductsAsync(page, pageSize);

            var response = req.CreateResponse(HttpStatusCode.OK);
            await response.WriteAsJsonAsync(ApiResponse<IEnumerable<ProductResponse>>.SuccessResponse(
                products.Select(MapToProductResponse)));
            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting products");
            var errorResponse = req.CreateResponse(HttpStatusCode.InternalServerError);
            await errorResponse.WriteAsJsonAsync(
                ApiResponse<object>.ErrorResponse("An error occurred while retrieving products"));
            return errorResponse;
        }
    }

    [Function("GetProductById")]
    public async Task<HttpResponseData> GetProductById(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "products/{id}")] HttpRequestData req,
        FunctionContext context,
        string id)
    {
        _logger.LogInformation($"Processing get product by id request: {id}");

        // Check if authentication failed
        if (context.Items.TryGetValue("AuthResult", out var authResult) && authResult is HttpResponseData authResponse)
        {
            return authResponse;
        }

        try
        {
            var product = await _productService.GetProductByIdAsync(id);

            if (product == null)
            {
                var notFoundResponse = req.CreateResponse(HttpStatusCode.NotFound);
                await notFoundResponse.WriteAsJsonAsync(
                    ApiResponse<object>.ErrorResponse("Product not found"));
                return notFoundResponse;
            }

            var response = req.CreateResponse(HttpStatusCode.OK);
            await response.WriteAsJsonAsync(ApiResponse<ProductResponse>.SuccessResponse(
                MapToProductResponse(product)));
            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting product by id");
            var errorResponse = req.CreateResponse(HttpStatusCode.InternalServerError);
            await errorResponse.WriteAsJsonAsync(
                ApiResponse<object>.ErrorResponse("An error occurred while retrieving the product"));
            return errorResponse;
        }
    }

    [Function("HealthCheck")]
    public HttpResponseData HealthCheck(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "health")] HttpRequestData req)
    {
        var response = req.CreateResponse(HttpStatusCode.OK);
        response.WriteString(JsonSerializer.Serialize(new { status = "healthy", service = "product" }));
        return response;
    }

    private static ProductResponse MapToProductResponse(Product product)
    {
        return new ProductResponse
        {
            Id = product.Id,
            Name = product.Name,
            Description = product.Description,
            Price = product.Price,
            Category = product.Category,
            Stock = product.Stock,
            IsActive = product.IsActive,
            CreatedBy = product.CreatedBy,
            CreatedAt = product.CreatedAt,
            UpdatedAt = product.UpdatedAt
        };
    }
}
