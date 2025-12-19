using System.Net;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using System.Text.Json;
using AuthService.Models;
using AuthService.Services;
using Shared.Models;
using System.ComponentModel.DataAnnotations;

namespace AuthService.Functions;

public class AuthFunctions
{
    private readonly ILogger<AuthFunctions> _logger;
    private readonly IAuthService _authService;

    public AuthFunctions(ILogger<AuthFunctions> logger, IAuthService authService)
    {
        _logger = logger;
        _authService = authService;
    }

    [Function("Register")]
    public async Task<HttpResponseData> Register(
        [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "auth/register")] HttpRequestData req)
    {
        _logger.LogInformation("Processing registration request");

        try
        {
            var requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            var request = JsonSerializer.Deserialize<RegisterRequest>(requestBody, new JsonSerializerOptions
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

            var user = await _authService.RegisterAsync(request);

            if (user == null)
            {
                var conflictResponse = req.CreateResponse(HttpStatusCode.Conflict);
                await conflictResponse.WriteAsJsonAsync(
                    ApiResponse<object>.ErrorResponse("User with this email already exists"));
                return conflictResponse;
            }

            var response = req.CreateResponse(HttpStatusCode.Created);
            await response.WriteAsJsonAsync(ApiResponse<object>.SuccessResponse(
                new { userId = user.Id, email = user.Email, userName = user.UserName },
                "User registered successfully"));
            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during registration");
            var errorResponse = req.CreateResponse(HttpStatusCode.InternalServerError);
            await errorResponse.WriteAsJsonAsync(
                ApiResponse<object>.ErrorResponse("An error occurred during registration"));
            return errorResponse;
        }
    }

    [Function("Login")]
    public async Task<HttpResponseData> Login(
        [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "auth/login")] HttpRequestData req)
    {
        _logger.LogInformation("Processing login request");

        try
        {
            var requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            var request = JsonSerializer.Deserialize<LoginRequest>(requestBody, new JsonSerializerOptions
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

            var authResponse = await _authService.LoginAsync(request);

            if (authResponse == null)
            {
                var unauthorizedResponse = req.CreateResponse(HttpStatusCode.Unauthorized);
                await unauthorizedResponse.WriteAsJsonAsync(
                    ApiResponse<object>.ErrorResponse("Invalid email or password"));
                return unauthorizedResponse;
            }

            var response = req.CreateResponse(HttpStatusCode.OK);
            await response.WriteAsJsonAsync(ApiResponse<AuthResponse>.SuccessResponse(
                authResponse, "Login successful"));
            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during login");
            var errorResponse = req.CreateResponse(HttpStatusCode.InternalServerError);
            await errorResponse.WriteAsJsonAsync(
                ApiResponse<object>.ErrorResponse("An error occurred during login"));
            return errorResponse;
        }
    }

    [Function("HealthCheck")]
    public HttpResponseData HealthCheck(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "health")] HttpRequestData req)
    {
        var response = req.CreateResponse(HttpStatusCode.OK);
        response.WriteString(JsonSerializer.Serialize(new { status = "healthy", service = "auth" }));
        return response;
    }
}
