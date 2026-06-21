using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace RentLanka.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddAdminRoleAndBanned : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "IsBanned",
                table: "Users",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<string>(
                name: "Role",
                table: "Users",
                type: "character varying(50)",
                maxLength: 50,
                nullable: false,
                defaultValue: "User");

            migrationBuilder.InsertData(
                table: "Users",
                columns: new[] { "Id", "AvatarUrl", "CreatedAt", "Email", "FirstName", "IsTrustedUser", "LastName", "NICNumber", "NicDocumentUrl", "PasswordHash", "PhoneNumber", "Role", "UpdatedAt", "VerificationLevel" },
                values: new object[] { new Guid("00000000-0000-0000-0000-000000000001"), null, new DateTime(2026, 6, 21, 0, 0, 0, 0, DateTimeKind.Utc), "admin@rentlanka.lk", "RentLanka", true, "Admin", null, null, "$2a$11$wE56M9gY0H6zZ94.yG7/feYV3YFhN27xKj5f0FwPzQ1g.b/X7S0.G", "0771234567", "Admin", null, 3 });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DeleteData(
                table: "Users",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0000-000000000001"));

            migrationBuilder.DropColumn(
                name: "IsBanned",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "Role",
                table: "Users");
        }
    }
}
