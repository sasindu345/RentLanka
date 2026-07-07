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
    public DbSet<Review> Reviews => Set<Review>();
    public DbSet<Conversation> Conversations => Set<Conversation>();
    public DbSet<Message> Messages => Set<Message>();
    public DbSet<Dispute> Disputes => Set<Dispute>();
    public DbSet<PlatformSetting> PlatformSettings => Set<PlatformSetting>();
    public DbSet<DeviceToken> DeviceTokens => Set<DeviceToken>();

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
            entity.Property(u => u.Role).IsRequired().HasMaxLength(50).HasDefaultValue("Renter");
            entity.Property(u => u.IsBanned).HasDefaultValue(false);
            entity.Property(u => u.RefreshTokenHash).HasMaxLength(512);
        });

        modelBuilder.Entity<User>().HasData(new User
        {
            Id = Guid.Parse("00000000-0000-0000-0000-000000000001"),
            Email = "admin@rentlanka.lk",
            PasswordHash = "$2a$11$I5A4FyWXZt6gZms37B3/2eXptXczfSN.9Mzgryhs5kGnaPnDzDKBS",
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

            entity.Property(l => l.Status).HasDefaultValue(ListingStatus.PendingApproval);

            entity.HasIndex(l => l.Category);
            entity.HasIndex(l => l.District);
            entity.HasIndex(l => l.IsPaused);
            entity.HasIndex(l => l.IsDeleted);
            entity.HasIndex(l => l.Status);

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
            entity.Property(b => b.RenterAgreementSigned).HasDefaultValue(false);
            entity.Property(b => b.OwnerAgreementSigned).HasDefaultValue(false);

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

        modelBuilder.Entity<Review>(entity =>
        {
            entity.HasKey(r => r.Id);
            entity.Property(r => r.Comment).HasMaxLength(2000);

            entity.HasOne(r => r.Booking)
                .WithMany()
                .HasForeignKey(r => r.BookingId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(r => r.Reviewer)
                .WithMany()
                .HasForeignKey(r => r.ReviewerId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(r => r.TargetUser)
                .WithMany()
                .HasForeignKey(r => r.TargetUserId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasIndex(r => new { r.BookingId, r.ReviewerId }).IsUnique();
            entity.HasIndex(r => r.TargetUserId);
        });

        modelBuilder.Entity<Conversation>(entity =>
        {
            entity.HasKey(c => c.Id);
            entity.Property(c => c.LastMessageContent).HasMaxLength(1000);

            entity.HasOne(c => c.UserOne)
                .WithMany()
                .HasForeignKey(c => c.UserOneId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(c => c.UserTwo)
                .WithMany()
                .HasForeignKey(c => c.UserTwoId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(c => c.Listing)
                .WithMany()
                .HasForeignKey(c => c.ListingId)
                .OnDelete(DeleteBehavior.SetNull);

            entity.HasIndex(c => c.LastMessageAt);
            entity.HasIndex(c => new { c.UserOneId, c.UserTwoId, c.ListingId }).IsUnique();
        });

        modelBuilder.Entity<Message>(entity =>
        {
            entity.HasKey(m => m.Id);
            entity.Property(m => m.Content).IsRequired().HasMaxLength(2000);

            entity.HasOne(m => m.Conversation)
                .WithMany(c => c.Messages)
                .HasForeignKey(m => m.ConversationId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(m => m.Sender)
                .WithMany()
                .HasForeignKey(m => m.SenderId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasIndex(m => m.CreatedAt);
        });

        modelBuilder.Entity<Dispute>(entity =>
        {
            entity.HasKey(d => d.Id);
            entity.Property(d => d.Reason).IsRequired().HasMaxLength(2000);
            entity.Property(d => d.AdminDecision).HasMaxLength(2000);

            entity.HasOne(d => d.Booking)
                .WithMany()
                .HasForeignKey(d => d.BookingId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(d => d.CreatedBy)
                .WithMany()
                .HasForeignKey(d => d.CreatedById)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(d => d.ResolvedBy)
                .WithMany()
                .HasForeignKey(d => d.ResolvedById)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasIndex(d => d.BookingId);
            entity.HasIndex(d => d.CreatedAt);
        });

        modelBuilder.Entity<PlatformSetting>(entity =>
        {
            entity.HasKey(ps => ps.Id);
            entity.Property(ps => ps.CommissionRate).HasColumnType("numeric(5,4)");
            entity.Property(ps => ps.CategoriesJson).IsRequired().HasMaxLength(2000);
        });

        modelBuilder.Entity<PlatformSetting>().HasData(new PlatformSetting
        {
            Id = Guid.Parse("00000000-0000-0000-0000-000000000001"),
            CommissionRate = 0.1000m,
            CategoriesJson = "[\"Photography\", \"Tools\", \"Camping\", \"Electronics\", \"Sports\", \"Other\"]",
            UpdatedAt = new DateTime(2026, 6, 21, 0, 0, 0, DateTimeKind.Utc)
        });

        modelBuilder.Entity<DeviceToken>(entity =>
        {
            entity.HasKey(dt => dt.Id);
            entity.Property(dt => dt.Token).IsRequired().HasMaxLength(1024);
            entity.Property(dt => dt.Platform).IsRequired().HasMaxLength(50);
            
            entity.HasOne(dt => dt.User)
                .WithMany()
                .HasForeignKey(dt => dt.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasIndex(dt => dt.Token).IsUnique();
            entity.HasIndex(dt => dt.UserId);
        });
    }
}
