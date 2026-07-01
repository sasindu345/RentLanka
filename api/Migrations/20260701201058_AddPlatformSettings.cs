using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace RentLanka.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddPlatformSettings : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "PlatformSettings",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    CommissionRate = table.Column<decimal>(type: "numeric(5,4)", nullable: false),
                    CategoriesJson = table.Column<string>(type: "character varying(2000)", maxLength: 2000, nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PlatformSettings", x => x.Id);
                });

            migrationBuilder.InsertData(
                table: "PlatformSettings",
                columns: new[] { "Id", "CategoriesJson", "CommissionRate", "UpdatedAt" },
                values: new object[] { new Guid("00000000-0000-0000-0000-000000000001"), "[\"Photography\", \"Tools\", \"Camping\", \"Electronics\", \"Sports\", \"Other\"]", 0.1000m, new DateTime(2026, 6, 21, 0, 0, 0, 0, DateTimeKind.Utc) });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "PlatformSettings");
        }
    }
}
