using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace RentLanka.Api.Migrations
{
    /// <inheritdoc />
    public partial class UpdateAdminPassword : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0000-000000000001"),
                column: "PasswordHash",
                value: "$2a$11$I5A4FyWXZt6gZms37B3/2eXptXczfSN.9Mzgryhs5kGnaPnDzDKBS");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: new Guid("00000000-0000-0000-0000-000000000001"),
                column: "PasswordHash",
                value: "$2a$11$6injpEU/eL1GA1EToj1rfu4AgtOLEmXKuRi4yiwwQQsqeukzts0iG");
        }
    }
}
