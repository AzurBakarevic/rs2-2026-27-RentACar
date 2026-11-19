using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace RentACar.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddPasswordReset : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "CodeSalt",
                table: "PasswordResetCodes",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<int>(
                name: "FailedAttempts",
                table: "PasswordResetCodes",
                type: "int",
                nullable: false,
                defaultValue: 0);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "CodeSalt",
                table: "PasswordResetCodes");

            migrationBuilder.DropColumn(
                name: "FailedAttempts",
                table: "PasswordResetCodes");
        }
    }
}
