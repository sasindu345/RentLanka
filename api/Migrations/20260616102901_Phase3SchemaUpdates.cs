using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace RentLanka.Api.Migrations
{
    /// <inheritdoc />
    public partial class Phase3SchemaUpdates : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "NicDocumentUrl",
                table: "Users",
                type: "character varying(2048)",
                maxLength: 2048,
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsDeleted",
                table: "Listings",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.CreateTable(
                name: "WishlistItems",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    ListingId = table.Column<Guid>(type: "uuid", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_WishlistItems", x => x.Id);
                    table.ForeignKey(
                        name: "FK_WishlistItems_Listings_ListingId",
                        column: x => x.ListingId,
                        principalTable: "Listings",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_WishlistItems_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Listings_Category",
                table: "Listings",
                column: "Category");

            migrationBuilder.CreateIndex(
                name: "IX_Listings_District",
                table: "Listings",
                column: "District");

            migrationBuilder.CreateIndex(
                name: "IX_Listings_IsDeleted",
                table: "Listings",
                column: "IsDeleted");

            migrationBuilder.CreateIndex(
                name: "IX_Listings_IsPaused",
                table: "Listings",
                column: "IsPaused");

            migrationBuilder.CreateIndex(
                name: "IX_Listings_OwnerId",
                table: "Listings",
                column: "OwnerId");

            migrationBuilder.CreateIndex(
                name: "IX_WishlistItems_ListingId",
                table: "WishlistItems",
                column: "ListingId");

            migrationBuilder.CreateIndex(
                name: "IX_WishlistItems_UserId_ListingId",
                table: "WishlistItems",
                columns: new[] { "UserId", "ListingId" },
                unique: true);

            migrationBuilder.AddForeignKey(
                name: "FK_Listings_Users_OwnerId",
                table: "Listings",
                column: "OwnerId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Listings_Users_OwnerId",
                table: "Listings");

            migrationBuilder.DropTable(
                name: "WishlistItems");

            migrationBuilder.DropIndex(
                name: "IX_Listings_Category",
                table: "Listings");

            migrationBuilder.DropIndex(
                name: "IX_Listings_District",
                table: "Listings");

            migrationBuilder.DropIndex(
                name: "IX_Listings_IsDeleted",
                table: "Listings");

            migrationBuilder.DropIndex(
                name: "IX_Listings_IsPaused",
                table: "Listings");

            migrationBuilder.DropIndex(
                name: "IX_Listings_OwnerId",
                table: "Listings");

            migrationBuilder.DropColumn(
                name: "NicDocumentUrl",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "IsDeleted",
                table: "Listings");
        }
    }
}
