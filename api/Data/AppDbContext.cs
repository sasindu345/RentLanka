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
    public DbSet<WishlistItem> WishlistItems => Set<WishlistItem>();
    public DbSet<Booking> Bookings => Set<Booking>();
    public DbSet<AvailabilityBlock> AvailabilityBlocks => Set<AvailabilityBlock>();
    public DbSet<Payment> Payments => Set<Payment>();
    public DbSet<Payout> Payouts => Set<Payout>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.HasPostgresExtension("postgis");

        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(u => u.Id);
            entity.HasIndex(u => u.Email).IsUnique();
            entity.Property(u => u.Email).IsRequired().HasMaxLength(256);
            entity.Property(u => u.PasswordHash).IsRequired();
            entity.Property(u => u.FirstName).IsRequired().HasMaxLength(100);
            entity.Property(u => u.LastName).IsRequired().HasMaxLength(100);
            entity.Property(u => u.PhoneNumber).HasMaxLength(20);
            entity.Property(u => u.NicDocumentUrl).HasMaxLength(2048);
            entity.Property(u => u.Role).IsRequired().HasMaxLength(50).HasDefaultValue("User");
            entity.Property(u => u.IsBanned).HasDefaultValue(false);
        });

        modelBuilder.Entity<User>().HasData(new User
        {
            Id = Guid.Parse("00000000-0000-0000-0000-000000000001"),
            Email = "admin@rentlanka.lk",
            PasswordHash = "$2a$11$6injpEU/eL1GA1EToj1rfu4AgtOLEmXKuRi4yiwwQQsqeukzts0iG",
            FirstName = "RentLanka",
            LastName = "Admin",
            PhoneNumber = "0771234567",
            VerificationLevel = VerificationLevel.Level3,
            IsTrustedUser = true,
            Role = "Admin",
            IsBanned = false,
            CreatedAt = new DateTime(2026, 6, 21, 0, 0, 0, DateTimeKind.Utc)
        });

        modelBuilder.Entity<Listing>(entity =>
        {
            entity.HasKey(l => l.Id);
            entity.Property(l => l.Title).IsRequired().HasMaxLength(200);
            entity.Property(l => l.Description).HasMaxLength(2000);
            entity.Property(l => l.Category).IsRequired().HasMaxLength(100);
            entity.Property(l => l.PricePerDay).HasColumnType("numeric(18,2)");
            entity.Property(l => l.SecurityDeposit).HasColumnType("numeric(18,2)");
            entity.Property(l => l.Rules).HasMaxLength(1000);
            entity.Property(l => l.District).IsRequired().HasMaxLength(100);
            entity.Property(l => l.Location).HasColumnType("geography(Point, 4326)");

            entity.HasIndex(l => l.Category);
            entity.HasIndex(l => l.District);
            entity.HasIndex(l => l.IsPaused);
            entity.HasIndex(l => l.IsDeleted);

            entity.HasOne(l => l.Owner)
                .WithMany(u => u.Listings)
                .HasForeignKey(l => l.OwnerId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<WishlistItem>(entity =>
        {
            entity.HasKey(w => w.Id);
            entity.HasIndex(w => new { w.UserId, w.ListingId }).IsUnique();

            entity.HasOne(w => w.User)
                .WithMany(u => u.WishlistItems)
                .HasForeignKey(w => w.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(w => w.Listing)
                .WithMany(l => l.WishlistItems)
                .HasForeignKey(w => w.ListingId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<Booking>(entity =>
        {
            entity.HasKey(b => b.Id);
            entity.Property(b => b.TotalPrice).HasColumnType("numeric(18,2)");
            entity.Property(b => b.SecurityDeposit).HasColumnType("numeric(18,2)");

            entity.HasOne(b => b.Listing)
                .WithMany()
                .HasForeignKey(b => b.ListingId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(b => b.Renter)
                .WithMany()
                .HasForeignKey(b => b.RenterId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<AvailabilityBlock>(entity =>
        {
            entity.HasKey(ab => ab.Id);

            entity.HasOne(ab => ab.Listing)
                .WithMany()
                .HasForeignKey(ab => ab.ListingId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(ab => ab.Booking)
                .WithMany()
                .HasForeignKey(ab => ab.BookingId)
                .OnDelete(DeleteBehavior.SetNull);

            entity.HasIndex(ab => new { ab.ListingId, ab.StartDate, ab.EndDate });
        });

        modelBuilder.Entity<Payment>(entity =>
        {
            entity.HasKey(p => p.Id);
            entity.Property(p => p.Amount).HasColumnType("numeric(18,2)");
            entity.Property(p => p.TransactionReference).HasMaxLength(100);

            entity.HasOne(p => p.Booking)
                .WithMany()
                .HasForeignKey(p => p.BookingId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<Payout>(entity =>
        {
            entity.HasKey(p => p.Id);
            entity.Property(p => p.Amount).HasColumnType("numeric(18,2)");
            entity.Property(p => p.BankName).IsRequired().HasMaxLength(100);
            entity.Property(p => p.AccountNumber).IsRequired().HasMaxLength(50);
            entity.Property(p => p.AccountName).IsRequired().HasMaxLength(100);

            entity.HasOne(p => p.Owner)
                .WithMany()
                .HasForeignKey(p => p.OwnerId)
                .OnDelete(DeleteBehavior.Restrict);
        });
    }
}
