using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Builder;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.IdentityModel.Tokens;
using RentLanka.Api.Data;
using RentLanka.Api.Middleware;
using RentLanka.Api.Services.Implementations;
using RentLanka.Api.Services.Interfaces;
using RentLanka.Api.Hubs;

using System;
using System.IO;

namespace RentLanka.Api;

public class Program
{
    public static void Main(string[] args)
    {
        // Load .env file if it exists
        var envPath = Path.Combine(Directory.GetCurrentDirectory(), ".env");
        if (!File.Exists(envPath))
        {
            envPath = Path.Combine(Directory.GetCurrentDirectory(), "..", ".env");
        }
        if (File.Exists(envPath))
        {
            Console.WriteLine($"[ENV LOADER] Loading environment configuration from {envPath}");
            foreach (var line in File.ReadAllLines(envPath))
            {
                var trimmedLine = line.Trim();
                if (string.IsNullOrEmpty(trimmedLine) || trimmedLine.StartsWith("#"))
                    continue;

                var parts = trimmedLine.Split('=', 2);
                if (parts.Length == 2)
                {
                    var key = parts[0].Trim();
                    var val = parts[1].Trim();
                    if (val.StartsWith("\"") && val.EndsWith("\""))
                    {
                        val = val.Substring(1, val.Length - 2);
                    }
                    else if (val.StartsWith("'") && val.EndsWith("'"))
                    {
                        val = val.Substring(1, val.Length - 2);
                    }
                    Environment.SetEnvironmentVariable(key, val);
                    var displayVal = (key.Contains("Pass", StringComparison.OrdinalIgnoreCase) || 
                                      key.Contains("Key", StringComparison.OrdinalIgnoreCase) || 
                                      key.Contains("Secret", StringComparison.OrdinalIgnoreCase)) 
                                      ? "********" : val;
                    Console.WriteLine($"[ENV LOADER] Set process env: {key} = {displayVal}");
                }
            }
        }
        else
        {
            Console.WriteLine($"[ENV LOADER] No .env file found at {envPath}");
        }

        var builder = WebApplication.CreateBuilder(args);

        // Add services to the container.
        builder.Services.AddControllers();

        builder.Services.AddCors(options =>
        {
            options.AddPolicy("RentLankaClients", policy =>
            {
                var allowedOrigins = builder.Configuration.GetSection("CorsSettings:AllowedOrigins").Get<string[]>();
                if (allowedOrigins != null && allowedOrigins.Length > 0)
                {
                    policy.WithOrigins(allowedOrigins)
                        .AllowAnyHeader()
                        .AllowAnyMethod()
                        .AllowCredentials();
                }
                else
                {
                    policy.WithOrigins(
                            "http://localhost:3000",
                            "http://127.0.0.1:3000",
                            "http://localhost:3001",
                            "http://127.0.0.1:3001",
                            "http://localhost:3002",
                            "http://127.0.0.1:3002")
                        .AllowAnyHeader()
                        .AllowAnyMethod()
                        .AllowCredentials();
                }
            });
        });


        // Database context registration
        var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
        
        // Load connection override from environment variable if present
        var envDbUrl = Environment.GetEnvironmentVariable("DATABASE_URL") ?? Environment.GetEnvironmentVariable("ConnectionStrings__DefaultConnection");
        if (!string.IsNullOrEmpty(envDbUrl))
        {
            connectionString = ConvertPostgresUriToConnectionString(envDbUrl);
            Console.WriteLine("[DB CONFIG] Using database connection override from environment variable.");
        }
        else
        {
            Console.WriteLine($"[DB CONFIG] Using local connection string from appsettings: Host={connectionString?.Split(';').FirstOrDefault(x => x.StartsWith("Host=", StringComparison.OrdinalIgnoreCase)) ?? "Not Specified"}");
        }

        builder.Services.AddDbContext<AppDbContext>(options =>
            options.UseNpgsql(connectionString,
                npgsqlOptions =>
                {
                    npgsqlOptions.MigrationsAssembly(typeof(AppDbContext).Assembly.FullName);
                    npgsqlOptions.UseNetTopologySuite();
                }));

        // Configure Authentication
        var secret = builder.Configuration["JwtSettings:Secret"];
        if (string.IsNullOrEmpty(secret))
        {
            if (builder.Environment.IsDevelopment())
            {
                secret = "super_secret_key_rentlanka_1234567890_long_enough";
                Console.WriteLine("[WARN] JwtSettings:Secret is empty. Falling back to development dummy key.");
            }
            else
            {
                throw new InvalidOperationException("CRITICAL: JwtSettings:Secret is not configured. The API cannot start in non-development mode without a signing key.");
            }
        }
        var issuer = builder.Configuration["JwtSettings:Issuer"] ?? "RentLanka";
        var audience = builder.Configuration["JwtSettings:Audience"] ?? "RentLankaUsers";


        builder.Services.AddAuthentication(options =>
        {
            options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
            options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
        })
        .AddJwtBearer(options =>
        {
            options.TokenValidationParameters = new TokenValidationParameters
            {
                ValidateIssuer = true,
                ValidateAudience = true,
                ValidateLifetime = true,
                ValidateIssuerSigningKey = true,
                ValidIssuer = issuer,
                ValidAudience = audience,
                IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secret))
            };

            options.Events = new JwtBearerEvents
            {
                OnMessageReceived = context =>
                {
                    var accessToken = context.Request.Query["access_token"];
                    var path = context.HttpContext.Request.Path;
                    
                    if (!string.IsNullOrEmpty(accessToken) && path.StartsWithSegments("/hubs/chat"))
                    {
                        context.Token = accessToken;
                    }
                    return Task.CompletedTask;
                }
            };
        });

        builder.Services.AddAuthorization();
        builder.Services.AddSignalR();

        // Register Dependency Injection Services
        builder.Services.AddScoped<IIdentityService, IdentityService>();
        builder.Services.AddScoped<IUserService, UserService>();
        builder.Services.AddScoped<IVerificationService, VerificationService>();
        builder.Services.AddScoped<IListingService, ListingService>();
        builder.Services.AddScoped<IWishlistService, WishlistService>();
        builder.Services.AddScoped<IAdminService, AdminService>();
        builder.Services.AddScoped<IBookingService, BookingService>();
        builder.Services.AddScoped<IEarningsService, EarningsService>();
        builder.Services.AddScoped<IReviewService, ReviewService>();
        builder.Services.AddScoped<IChatService, ChatService>();
        builder.Services.AddScoped<IDisputeService, DisputeService>();
        builder.Services.AddScoped<ISettingsService, SettingsService>();
        builder.Services.AddScoped<INotificationService, FcmNotificationService>();
        builder.Services.AddHttpClient<IEmailService, EmailService>();
        builder.Services.AddHttpClient<ISmsService, SmsService>();
        builder.Services.AddHttpClient<IAiService, GeminiAiService>();
        
        var storageProvider = builder.Configuration["FileStorageSettings:Provider"] ?? "Local";
        if (storageProvider.Equals("S3", StringComparison.OrdinalIgnoreCase))
        {
            builder.Services.AddSingleton<IFileStorageService, S3FileStorageService>();
        }
        else
        {
            builder.Services.AddSingleton<IFileStorageService, CloudinaryFileStorageService>();
        }

        // Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
        builder.Services.AddOpenApi();

        var app = builder.Build();

        var webRoot = app.Environment.WebRootPath ?? Path.Combine(app.Environment.ContentRootPath, "wwwroot");
        Directory.CreateDirectory(Path.Combine(webRoot, "uploads"));

        // Configure the HTTP request pipeline.
        app.UseMiddleware<ExceptionMiddleware>();

        if (app.Environment.IsDevelopment())
        {
            app.MapOpenApi();
        }
        else
        {
            app.UseHttpsRedirection();
        }

        app.UseCors("RentLankaClients");


        app.UseStaticFiles();

        app.UseAuthentication();
        app.UseAuthorization();

        app.MapControllers();
        app.MapHub<ChatHub>("/hubs/chat");
        
        // Simple health check endpoint for Azure ping probes
        app.MapGet("/health", () => Results.Ok("healthy"));


        app.Run();
    }

    private static string ConvertPostgresUriToConnectionString(string uriString)
    {
        if (string.IsNullOrWhiteSpace(uriString))
        {
            return uriString;
        }

        uriString = uriString.Trim('"', '\'').Trim();

        if (!uriString.StartsWith("postgres://", StringComparison.OrdinalIgnoreCase) && 
            !uriString.StartsWith("postgresql://", StringComparison.OrdinalIgnoreCase))
        {
            return uriString;
        }

        try
        {
            var uri = new Uri(uriString);
            var userInfo = uri.UserInfo.Split(':');
            var username = userInfo[0];
            var password = userInfo.Length > 1 ? userInfo[1] : "";
            var host = uri.Host;
            var port = uri.Port > 0 ? uri.Port : 5432;
            var database = uri.AbsolutePath.TrimStart('/');

            var connStr = $"Host={host};Port={port};Database={database};Username={username};Password={password};";

            // Enforce SSL Mode for Neon DB remote connections
            if (uriString.Contains("sslmode=require", StringComparison.OrdinalIgnoreCase) || 
                uriString.Contains("sslmode=prefer", StringComparison.OrdinalIgnoreCase) ||
                uriString.Contains("sslmode=disable", StringComparison.OrdinalIgnoreCase))
            {
                if (uriString.Contains("sslmode=require", StringComparison.OrdinalIgnoreCase))
                {
                    connStr += "SSL Mode=Require;Trust Server Certificate=true;";
                }
                else if (uriString.Contains("sslmode=prefer", StringComparison.OrdinalIgnoreCase))
                {
                    connStr += "SSL Mode=Prefer;Trust Server Certificate=true;";
                }
                else if (uriString.Contains("sslmode=disable", StringComparison.OrdinalIgnoreCase))
                {
                    connStr += "SSL Mode=Disable;";
                }
            }
            else
            {
                // Default to SSL Mode Require for security with Neon
                connStr += "SSL Mode=Require;Trust Server Certificate=true;";
            }

            return connStr;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[DB CONFIG] Error converting postgres URI: {ex.Message}");
            return uriString;
        }
    }
}
