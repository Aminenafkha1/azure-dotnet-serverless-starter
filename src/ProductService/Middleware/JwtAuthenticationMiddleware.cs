using System.IdentityModel.Tokens.Jwt;
using System.Net;
using System.Security.Claims;
using System.Text;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Azure.Functions.Worker.Middleware;
using Microsoft.Extensions.Logging;
using Microsoft.IdentityModel.Tokens;
using Shared.Models;

namespace ProductService.Middleware;

public class JwtAuthenticationMiddleware : IFunctionsWorkerMiddleware
{
    private readonly JwtSettings _jwtSettings;
    private readonly ILogger<JwtAuthenticationMiddleware> _logger;

    public JwtAuthenticationMiddleware(JwtSettings jwtSettings, ILogger<JwtAuthenticationMiddleware> logger)
    {
        _jwtSettings = jwtSettings;
        _logger = logger;
    }

    public async Task Invoke(FunctionContext context, FunctionExecutionDelegate next)
    {
        var requestData = await context.GetHttpRequestDataAsync();

        if (requestData == null)
        {
            await next(context);
            return;
        }

        // Skip authentication for health check
        if (requestData.Url.AbsolutePath.Contains("/health"))
        {
            await next(context);
            return;
        }

        var authHeader = requestData.Headers.FirstOrDefault(h =>
            h.Key.Equals("Authorization", StringComparison.OrdinalIgnoreCase));

        if (authHeader.Value == null || !authHeader.Value.Any())
        {
            _logger.LogWarning("Missing authorization header for {Path}", requestData.Url.AbsolutePath);
            context.Items["AuthResult"] = CreateUnauthorizedResponse(requestData, "Missing authorization header");
            await next(context);
            return;
        }

        var token = authHeader.Value.First()?.Replace("Bearer ", "", StringComparison.OrdinalIgnoreCase);

        if (string.IsNullOrEmpty(token))
        {
            _logger.LogWarning("Invalid token format for {Path}", requestData.Url.AbsolutePath);
            context.Items["AuthResult"] = CreateUnauthorizedResponse(requestData, "Invalid token format");
            await next(context);
            return;
        }

        try
        {
            var tokenHandler = new JwtSecurityTokenHandler();
            var key = Encoding.UTF8.GetBytes(_jwtSettings.Secret);

            var validationParameters = new TokenValidationParameters
            {
                ValidateIssuerSigningKey = true,
                IssuerSigningKey = new SymmetricSecurityKey(key),
                ValidateIssuer = true,
                ValidIssuer = _jwtSettings.Issuer,
                ValidateAudience = true,
                ValidAudience = _jwtSettings.Audience,
                ValidateLifetime = true,
                ClockSkew = TimeSpan.Zero
            };

            var principal = tokenHandler.ValidateToken(token, validationParameters, out var validatedToken);

            // Store claims in context
            context.Items["User"] = principal;
            context.Items["UserId"] = principal.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            await next(context);
        }
        catch (SecurityTokenExpiredException)
        {
            _logger.LogWarning("Token expired for {Path}", requestData.Url.AbsolutePath);
            context.Items["AuthResult"] = CreateUnauthorizedResponse(requestData, "Token expired");
            await next(context);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Token validation failed for {Path}", requestData.Url.AbsolutePath);
            context.Items["AuthResult"] = CreateUnauthorizedResponse(requestData, "Invalid token");
            await next(context);
        }
    }

    private HttpResponseData CreateUnauthorizedResponse(HttpRequestData request, string message)
    {
        var response = request.CreateResponse();
        response.StatusCode = HttpStatusCode.Unauthorized;
        response.Headers.Add("Content-Type", "application/json; charset=utf-8");
        var errorResponse = ApiResponse<object>.ErrorResponse(message);
        response.WriteStringAsync(System.Text.Json.JsonSerializer.Serialize(errorResponse)).GetAwaiter().GetResult();
        return response;
    }
}
