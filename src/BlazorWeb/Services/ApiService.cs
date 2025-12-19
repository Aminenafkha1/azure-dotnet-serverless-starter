using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;

namespace BlazorWeb.Services;

public class ApiService
{
    private readonly HttpClient _httpClient;
    private readonly IConfiguration _configuration;
    private string? _authToken;

    public ApiService(HttpClient httpClient, IConfiguration configuration)
    {
        _httpClient = httpClient;
        _configuration = configuration;
    }

    public bool IsAuthenticated => !string.IsNullOrEmpty(_authToken);

    private void SetAuthHeader()
    {
        if (!string.IsNullOrEmpty(_authToken))
        {
            _httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", _authToken);
        }
    }

    public async Task<ApiResponse<LoginResponse>> RegisterAsync(RegisterRequest request)
    {
        var authBaseUrl = _configuration["ApiSettings:AuthServiceUrl"];
        var response = await _httpClient.PostAsJsonAsync($"{authBaseUrl}/api/auth/register", request);
        var result = await response.Content.ReadFromJsonAsync<ApiResponse<LoginResponse>>();
        return result ?? ApiResponse<LoginResponse>.ErrorResponse("Invalid response from server");
    }

    public async Task<ApiResponse<LoginResponse>> LoginAsync(LoginRequest request)
    {
        var authBaseUrl = _configuration["ApiSettings:AuthServiceUrl"];
        var response = await _httpClient.PostAsJsonAsync($"{authBaseUrl}/api/auth/login", request);
        var result = await response.Content.ReadFromJsonAsync<ApiResponse<LoginResponse>>();

        if (result?.Success == true && result.Data != null)
        {
            _authToken = result.Data.Token;
            SetAuthHeader();
        }

        return result ?? ApiResponse<LoginResponse>.ErrorResponse("Invalid response from server");
    }

    public void Logout()
    {
        _authToken = null;
        _httpClient.DefaultRequestHeaders.Authorization = null;
    }

    public async Task<ApiResponse<IEnumerable<ProductResponse>>> GetProductsAsync()
    {
        SetAuthHeader();
        var productBaseUrl = _configuration["ApiSettings:ProductServiceUrl"];
        var response = await _httpClient.GetAsync($"{productBaseUrl}/api/products");
        var result = await response.Content.ReadFromJsonAsync<ApiResponse<IEnumerable<ProductResponse>>>();
        return result ?? ApiResponse<IEnumerable<ProductResponse>>.ErrorResponse("Invalid response from server");
    }

    public async Task<ApiResponse<ProductResponse>> GetProductAsync(string id)
    {
        SetAuthHeader();
        var productBaseUrl = _configuration["ApiSettings:ProductServiceUrl"];
        var response = await _httpClient.GetAsync($"{productBaseUrl}/api/products/{id}");
        var result = await response.Content.ReadFromJsonAsync<ApiResponse<ProductResponse>>();
        return result ?? ApiResponse<ProductResponse>.ErrorResponse("Invalid response from server");
    }

    public async Task<ApiResponse<ProductResponse>> CreateProductAsync(CreateProductRequest request)
    {
        SetAuthHeader();
        var productBaseUrl = _configuration["ApiSettings:ProductServiceUrl"];
        var response = await _httpClient.PostAsJsonAsync($"{productBaseUrl}/api/products", request);
        var result = await response.Content.ReadFromJsonAsync<ApiResponse<ProductResponse>>();
        return result ?? ApiResponse<ProductResponse>.ErrorResponse("Invalid response from server");
    }

    public async Task<ApiResponse<ProductResponse>> UpdateProductAsync(string id, UpdateProductRequest request)
    {
        SetAuthHeader();
        var productBaseUrl = _configuration["ApiSettings:ProductServiceUrl"];
        var response = await _httpClient.PutAsJsonAsync($"{productBaseUrl}/api/products/{id}", request);
        var result = await response.Content.ReadFromJsonAsync<ApiResponse<ProductResponse>>();
        return result ?? ApiResponse<ProductResponse>.ErrorResponse("Invalid response from server");
    }

    public async Task<ApiResponse<object>> DeleteProductAsync(string id)
    {
        SetAuthHeader();
        var productBaseUrl = _configuration["ApiSettings:ProductServiceUrl"];
        var response = await _httpClient.DeleteAsync($"{productBaseUrl}/api/products/{id}");
        var result = await response.Content.ReadFromJsonAsync<ApiResponse<object>>();
        return result ?? ApiResponse<object>.ErrorResponse("Invalid response from server");
    }
}

// DTOs
public class ApiResponse<T>
{
    public bool Success { get; set; }
    public T? Data { get; set; }
    public string? Message { get; set; }
    public List<string>? Errors { get; set; }

    public static ApiResponse<T> ErrorResponse(string message)
    {
        return new ApiResponse<T> { Success = false, Message = message };
    }
}

public class RegisterRequest
{
    public string Email { get; set; } = string.Empty;
    public string UserName { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
}

public class LoginRequest
{
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
}

public class LoginResponse
{
    public string Token { get; set; } = string.Empty;
    public string UserId { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string UserName { get; set; } = string.Empty;
    public DateTime ExpiresAt { get; set; }
}

public class ProductResponse
{
    public string Id { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public string Category { get; set; } = string.Empty;
    public int Stock { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}

public class CreateProductRequest
{
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public string Category { get; set; } = string.Empty;
    public int Stock { get; set; }
}

public class UpdateProductRequest
{
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public string Category { get; set; } = string.Empty;
    public int Stock { get; set; }
}
