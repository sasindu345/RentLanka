using Microsoft.EntityFrameworkCore;
using RentLanka.Api.Models.Entities;

namespace RentLanka.Api.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options)
        : base(options)
    {
    }

    public DbSet<User> Users => Set<User>();
    public DbSet<Listing> Listings => Set<Listing>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Enable PostGIS extension
        modelBuilder.HasPostgresExtension("postgis");
        
        // Apply configurations directly
        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(u => u.Id);
            entity.HasIndex(u => u.Email).IsUnique();
            entity.Property(u => u.Email).IsRequired().HasMaxLength(256);
            entity.Property(u => u.PasswordHash).IsRequired();
            entity.Property(u => u.FirstName).IsRequired().HasMaxLength(100);
            entity.Property(u => u.LastName).IsRequired().HasMaxLength(100);
            entity.Property(u => u.PhoneNumber).HasMaxLength(20);
        });

        modelBuilder.Entity<Listing>(entity =>
        {
            entity.HasKey(l => l.Id);
            entity.Property(l => l.OwnerId).IsRequired();
            entity.Property(l => l.Title).IsRequired().HasMaxLength(200);
            entity.Property(l => l.Description).HasMaxLength(2000);
            entity.Property(l => l.Category).IsRequired().HasMaxLength(100);
            entity.Property(l => l.PricePerDay).HasColumnType("numeric(18,2)");
            entity.Property(l => l.SecurityDeposit).HasColumnType("numeric(18,2)");
            entity.Property(l => l.Rules).HasMaxLength(1000);
            entity.Property(l => l.District).IsRequired().HasMaxLength(100);
            
            // Map location property to PostGIS geography point with SRID 4326
            entity.Property(l => l.Location).HasColumnType("geography(Point, 4326)");
        });
    }
}
