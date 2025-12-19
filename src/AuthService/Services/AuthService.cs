using Microsoft.Azure.Cosmos;
using AuthService.Models;
using Shared.Infrastructure;
using UserModel = AuthService.Models.User;

namespace AuthService.Services;

public interface IAuthService
{
    Task<UserModel?> RegisterAsync(RegisterRequest request);
    Task<AuthResponse?> LoginAsync(LoginRequest request);
    Task<UserModel?> GetUserByEmailAsync(string email);
}

public class AuthService : IAuthService
{
    private readonly Container _userContainer;
    private readonly IJwtTokenService _jwtTokenService;

    public AuthService(ICosmosDbService cosmosDbService, IJwtTokenService jwtTokenService)
    {
        _userContainer = cosmosDbService.GetContainer("Users");
        _jwtTokenService = jwtTokenService;
    }

    public async Task<UserModel?> RegisterAsync(RegisterRequest request)
    {
        // Check if user already exists
        var existingUser = await GetUserByEmailAsync(request.Email);
        if (existingUser != null)
        {
            return null;
        }

        // Hash password
        var passwordHash = BCrypt.Net.BCrypt.HashPassword(request.Password);

        // Create user
        var user = new UserModel
        {
            Email = request.Email.ToLowerInvariant(),
            UserName = request.UserName,
            PasswordHash = passwordHash,
            FirstName = request.FirstName,
            LastName = request.LastName
        };

        try
        {
            var response = await _userContainer.CreateItemAsync(user, new PartitionKey(user.Id));
            return response.Resource;
        }
        catch (CosmosException ex) when (ex.StatusCode == System.Net.HttpStatusCode.Conflict)
        {
            return null;
        }
    }

    public async Task<AuthResponse?> LoginAsync(LoginRequest request)
    {
        var user = await GetUserByEmailAsync(request.Email);

        if (user == null || !user.IsActive)
        {
            return null;
        }

        // Verify password
        if (!BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
        {
            return null;
        }

        // Generate JWT token
        var token = _jwtTokenService.GenerateToken(user);
        var expiresAt = DateTime.UtcNow.AddMinutes(_jwtTokenService.GetExpirationMinutes());

        return new AuthResponse
        {
            Token = token,
            UserId = user.Id,
            Email = user.Email,
            UserName = user.UserName,
            ExpiresAt = expiresAt
        };
    }

    public async Task<UserModel?> GetUserByEmailAsync(string email)
    {
        var query = new QueryDefinition("SELECT * FROM c WHERE c.email = @email")
            .WithParameter("@email", email.ToLowerInvariant());

        var iterator = _userContainer.GetItemQueryIterator<UserModel>(query);

        if (iterator.HasMoreResults)
        {
            var response = await iterator.ReadNextAsync();
            return response.FirstOrDefault();
        }

        return null;
    }
}
