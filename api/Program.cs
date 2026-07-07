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
using Serilog;
using Serilog.Events;
using Serilog.Formatting.Compact;
using Microsoft.ApplicationInsights.Extensibility;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.AspNetCore.Http;

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

        // Initialize Serilog bootstrap logger
        Log.Logger = new LoggerConfiguration()
            .MinimumLevel.Debug()
            .MinimumLevel.Override("Microsoft", LogEventLevel.Information)
            .Enrich.FromLogContext()
            .WriteTo.Console(new CompactJsonFormatter())
            .CreateBootstrapLogger();

        try
        {
            Log.Information("Configuring host and services...");

            var builder = WebApplication.CreateBuilder(args);

            // Configure Serilog
            builder.Host.UseSerilog((context, services, configuration) =>
            {
                configuration
                    .ReadFrom.Configuration(context.Configuration)
                    .ReadFrom.Services(services)
                    .Enrich.FromLogContext()
                    .WriteTo.Console(new CompactJsonFormatter());

                var telemetryConfig = services.GetService<TelemetryConfiguration>();
                if (telemetryConfig != null)
                {
                    configuration.WriteTo.ApplicationInsights(telemetryConfig, TelemetryConverter.Traces);
                }
            });

            // Add services to the container.
            builder.Services.AddApplicationInsightsTelemetry();
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

        // Dynamically enforce connection limits to protect Neon DB connection boundaries
        if (!string.IsNullOrEmpty(connectionString))
        {
            if (!connectionString.EndsWith(";"))
            {
                connectionString += ";";
            }
            if (!connectionString.Contains("Max Pool Size=", StringComparison.OrdinalIgnoreCase))
            {
                connectionString += "Max Pool Size=8;Connection Timeout=15;";
            }
        }

        builder.Services.AddDbContextPool<AppDbContext>(options =>
            options.UseNpgsql(connectionString,
                npgsqlOptions =>
                {
                    npgsqlOptions.MigrationsAssembly(typeof(AppDbContext).Assembly.FullName);
                    npgsqlOptions.UseNetTopologySuite();
                    npgsqlOptions.EnableRetryOnFailure(
                        maxRetryCount: 3,
                        maxRetryDelay: TimeSpan.FromSeconds(5),
                        errorCodesToAdd: null);
                }));

        // Configure Rate Limiting
        builder.Services.AddRateLimiter(options =>
        {
            options.AddFixedWindowLimiter("AuthLimit", opt =>
            {
                opt.Window = TimeSpan.FromMinutes(1);
                opt.PermitLimit = 10;
                opt.QueueLimit = 0;
            });
            options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
        });

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
        builder.Services.AddOpenApi(options =>
        {
            options.AddDocumentTransformer((document, context, cancellationToken) =>
            {
                document.Info.Title = "RentLanka API";
                document.Info.Version = "v1";
                document.Info.Description = "RentLanka Peer-to-Peer Rental Marketplace API Backend Services";

                // Add JWT Security Scheme
                var securityScheme = new Microsoft.OpenApi.OpenApiSecurityScheme
                {
                    Type = Microsoft.OpenApi.SecuritySchemeType.Http,
                    Scheme = "bearer",
                    BearerFormat = "JWT",
                    Description = "Enter your JWT token. Format: Bearer {token}"
                };

                document.Components ??= new Microsoft.OpenApi.OpenApiComponents();
                document.Components.SecuritySchemes.Add("Bearer", securityScheme);

                // Enforce global security requirement for authorization testing in swagger
                document.Security.Add(new Microsoft.OpenApi.OpenApiSecurityRequirement
                {
                    { new Microsoft.OpenApi.OpenApiSecuritySchemeReference("Bearer", document), new List<string>() }
                });

                return Task.CompletedTask;
            });
        });

        var app = builder.Build();

        var webRoot = app.Environment.WebRootPath ?? Path.Combine(app.Environment.ContentRootPath, "wwwroot");
        Directory.CreateDirectory(Path.Combine(webRoot, "uploads"));

        // Configure the HTTP request pipeline.
        app.UseMiddleware<CorrelationIdMiddleware>();
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

        app.UseRateLimiter();

        app.UseStaticFiles();

        app.UseAuthentication();
        app.UseAuthorization();

        app.MapControllers();
        app.MapHub<ChatHub>("/hubs/chat");
        
        // Simple health check endpoint for Azure ping probes
        app.MapGet("/health", () => Results.Ok("healthy"));


        app.Run();
        }
        catch (Exception ex)
        {
            Log.Fatal(ex, "Host terminated unexpectedly");
        }
        finally
        {
            Log.CloseAndFlush();
        }
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
