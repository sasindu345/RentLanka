using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using RentLanka.Application.Common.Interfaces;
using RentLanka.Infrastructure.Identity;
using RentLanka.Infrastructure.Persistence;
using RentLanka.Infrastructure.Storage;
using RentLanka.Infrastructure.Verification;

namespace RentLanka.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructureServices(this IServiceCollection services, IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("DefaultConnection");

        services.AddDbContext<ApplicationDbContext>(options =>
            options.UseNpgsql(connectionString,
                builder => builder.MigrationsAssembly(typeof(ApplicationDbContext).Assembly.FullName)));

        services.AddScoped<IApplicationDbContext>(provider => provider.GetRequiredService<ApplicationDbContext>());
        services.AddScoped<IIdentityService, IdentityService>();
        services.AddScoped<IVerificationService, VerificationService>();
        services.AddSingleton<IFileStorageService, S3FileStorageService>();

        return services;
    }
}
