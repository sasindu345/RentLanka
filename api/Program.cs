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
            });
        });

        // Database context registration
        var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
        builder.Services.AddDbContext<AppDbContext>(options =>
            options.UseNpgsql(connectionString,
                npgsqlOptions =>
                {
                    npgsqlOptions.MigrationsAssembly(typeof(AppDbContext).Assembly.FullName);
                    npgsqlOptions.UseNetTopologySuite();
                }));

        // Configure Authentication
        var secret = builder.Configuration["JwtSettings:Secret"] ?? "super_secret_key_rentlanka_1234567890_long_enough";
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
        });

        builder.Services.AddAuthorization();

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
        builder.Services.AddHttpClient<IEmailService, EmailService>();
        builder.Services.AddHttpClient<ISmsService, SmsService>();
        builder.Services.AddSingleton<IFileStorageService, S3FileStorageService>();

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

        app.UseCors("RentLankaClients");

        app.UseStaticFiles();

        app.UseAuthentication();
        app.UseAuthorization();

        app.MapControllers();

        app.Run();
    }
}
