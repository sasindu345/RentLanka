using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace RentLanka.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddRoleSeparationAndListingApproval : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<string>(
                name: "Role",
                table: "Users",
                type: "character varying(50)",
                maxLength: 50,
                nullable: false,
                defaultValue: "Renter",
                oldClrType: typeof(string),
                oldType: "character varying(50)",
                oldMaxLength: 50,
                oldDefaultValue: "User");

            migrationBuilder.AddColumn<int>(
                name: "Status",
                table: "Listings",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<bool>(
                name: "OwnerAgreementSigned",
                table: "Bookings",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "RenterAgreementSigned",
                table: "Bookings",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.CreateIndex(
                name: "IX_Listings_Status",
                table: "Listings",
                column: "Status");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Listings_Status",
                table: "Listings");

            migrationBuilder.DropColumn(
                name: "Status",
                table: "Listings");

            migrationBuilder.DropColumn(
                name: "OwnerAgreementSigned",
                table: "Bookings");

            migrationBuilder.DropColumn(
                name: "RenterAgreementSigned",
                table: "Bookings");

            migrationBuilder.AlterColumn<string>(
                name: "Role",
                table: "Users",
                type: "character varying(50)",
                maxLength: 50,
                nullable: false,
                defaultValue: "User",
                oldClrType: typeof(string),
                oldType: "character varying(50)",
                oldMaxLength: 50,
                oldDefaultValue: "Renter");
        }
    }
}
