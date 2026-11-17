using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace RentACar.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddAuthentication : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "TokenVersion",
                table: "Users",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.InsertData(
                table: "Users",
                columns: new[] { "Id", "CreatedAt", "DriverLicenseNumber", "DriverLicenseValidUntil", "Email", "FirstName", "IsActive", "IsDeleted", "LastName", "PasswordHash", "PasswordSalt", "PhoneNumber", "ProfileImage", "RoleId", "TokenVersion", "Username" },
                values: new object[,]
                {
                    { 1, new DateTime(2026, 11, 1, 0, 0, 0, 0, DateTimeKind.Utc), null, null, "desktop@rentacar.ba", "Desktop", true, false, "Administrator", "bpKhlFuFnXOr/mgD1B3opMA3Kwvj6BtWeeD6HNxMKs4=", "XFq/dUV9C+XN/eJuP7yecQ==", "+387 61 000 001", null, 1, 0, "desktop" },
                    { 2, new DateTime(2026, 11, 1, 0, 0, 0, 0, DateTimeKind.Utc), "B1234567", new DateOnly(2030, 12, 31), "mobile@rentacar.ba", "Mobile", true, false, "Korisnik", "2Wg9Cdny4XenV98HS7I2Dta6f4KdSPy2ZBspXxtBgsU=", "4nkpZcAsz3yJjiRaT/LzfQ==", "+387 61 000 002", null, 2, 0, "mobile" }
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DeleteData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 2);

            migrationBuilder.DropColumn(
                name: "TokenVersion",
                table: "Users");
        }
    }
}
