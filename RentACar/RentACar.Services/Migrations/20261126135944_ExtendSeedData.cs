using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace RentACar.Services.Migrations
{
    /// <inheritdoc />
    public partial class ExtendSeedData : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.InsertData(
                table: "SeasonalPrices",
                columns: new[] { "Id", "EndDate", "IncreasePercentage", "IsActive", "Name", "StartDate" },
                values: new object[,]
                {
                    { 3, new DateOnly(2026, 1, 5), 10m, true, "Zimski praznici 2025/26", new DateOnly(2025, 12, 20) },
                    { 4, new DateOnly(2026, 9, 15), 20m, true, "Ljetna sezona 2026", new DateOnly(2026, 6, 15) }
                });

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 1,
                column: "CreatedAt",
                value: new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 2,
                column: "CreatedAt",
                value: new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.InsertData(
                table: "Users",
                columns: new[] { "Id", "CreatedAt", "DriverLicenseNumber", "DriverLicenseValidUntil", "Email", "FirstName", "IsActive", "IsDeleted", "LastName", "PasswordHash", "PasswordSalt", "PhoneNumber", "ProfileImage", "RoleId", "TokenVersion", "Username" },
                values: new object[,]
                {
                    { 3, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "B2045871", new DateOnly(2031, 5, 14), "amar.hodzic@example.com", "Amar", true, false, "Hodžić", "lzE40nRVpxBs+MVoHgIdwA8/O5NS9dK3wHethUpCwns=", "9Uta9HEWzBKuy6UV1fVumg==", "+387 61 482 115", null, 2, 0, "amar.hodzic" },
                    { 4, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "B1187342", new DateOnly(2029, 3, 2), "senad.begovic@example.com", "Senad", true, false, "Begović", "P2yvjqSKQ+gRoilb91v5koztyp2YY12hhAcZSnCygqE=", "PFJxm05K4Z4U6BJurntsQQ==", "+387 62 315 904", null, 2, 0, "senad.begovic" },
                    { 5, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "B3390126", new DateOnly(2032, 9, 21), "kenan.mujic@example.com", "Kenan", true, false, "Mujić", "kMkhg2Ra+Khfp1fLb1RGwGt0z1FgxXi9a2xVLbG2MxE=", "3azjIXMUIVDGzOb/R19W7w==", "+387 61 774 230", null, 2, 0, "kenan.mujic" },
                    { 6, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "B2861457", new DateOnly(2030, 1, 30), "emir.delic@example.com", "Emir", true, false, "Delić", "45ZaA048t1kSMdMtZN9cXwFdcxxGe573HPfZpTqQ+eM=", "uQnOdmkhAmNggVXDv2U/oA==", "+387 63 208 657", null, 2, 0, "emir.delic" },
                    { 7, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "B3012784", new DateOnly(2033, 6, 8), "haris.sabic@example.com", "Haris", true, false, "Šabić", "TFqxyzCPJmdwqd0lit6jWSGDbcX4YLGmYLtgqZlJ6r4=", "T6DZwYRtb5t5AzwGCkPoQA==", "+387 65 541 398", null, 2, 0, "haris.sabic" },
                    { 8, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "B3547219", new DateOnly(2034, 2, 17), "tarik.kovacevic@example.com", "Tarik", true, false, "Kovačević", "XDKuFLEyNy3uRt7QZFINkdtWoFjWdgi94FroONFTLEE=", "Khlnvdj0evmCcBSlWePOWg==", "+387 66 129 870", null, 2, 0, "tarik.kovacevic" },
                    { 9, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "B2493068", new DateOnly(2031, 11, 3), "lejla.hasic@example.com", "Lejla", true, false, "Hasić", "AkRRBr1+3epfdxee5s+3NJ2axyMofOysbSMSjVXbXRE=", "wQ7OxgBgjaMEzhSOBEatXQ==", "+387 61 903 462", null, 2, 0, "lejla.hasic" },
                    { 10, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "B1958340", new DateOnly(2029, 8, 25), "amina.omerovic@example.com", "Amina", true, false, "Omerović", "mSbIM9LETI4VbpPdQdAErACvl2XxhgFxSmTredIZew4=", "K02GgsZdenkWUtRZAZ8uPA==", "+387 62 650 781", null, 2, 0, "amina.omerovic" },
                    { 11, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "B2718903", new DateOnly(2032, 4, 12), "selma.karic@example.com", "Selma", true, false, "Karić", "WcPz9siPE2OiYjzFo3T4Ejuyzannptp9+j7o3dKtjnM=", "52o15A9Ov9G5tj8DP7UKrQ==", "+387 61 237 514", null, 2, 0, "selma.karic" },
                    { 12, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "B3204675", new DateOnly(2033, 10, 9), "ajla.mehmedovic@example.com", "Ajla", true, false, "Mehmedović", "ZkTYwE0+sCbPIxEQ3FLosvN8voWhxSHk2my+EAcQPwo=", "2rqNRUP5FiPTMVnDdBYIvw==", "+387 63 486 029", null, 2, 0, "ajla.mehmedovic" },
                    { 13, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "B1640592", new DateOnly(2030, 7, 19), "merima.avdic@example.com", "Merima", false, false, "Avdić", "MKWjXeSrzESg2il8YJrms3qpX79hxNzSVD4I1mG20cc=", "YdG9VTrIAys4Vn59HsyuUg==", "+387 61 815 346", null, 2, 0, "merima.avdic" },
                    { 14, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "B3681240", new DateOnly(2034, 12, 1), "dzana.softic@example.com", "Džana", true, false, "Softić", "ogyFhNie3Qehc9zQT1EYjfdtGr+coquO7je/AfqToSE=", "OAfAfPJU6wz8cPuxVP2xrg==", "+387 62 097 153", null, 2, 0, "dzana.softic" }
                });

            migrationBuilder.UpdateData(
                table: "Vehicles",
                keyColumn: "Id",
                keyValue: 1,
                column: "CreatedAt",
                value: new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Vehicles",
                keyColumn: "Id",
                keyValue: 2,
                column: "CreatedAt",
                value: new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Vehicles",
                keyColumn: "Id",
                keyValue: 3,
                column: "CreatedAt",
                value: new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Vehicles",
                keyColumn: "Id",
                keyValue: 4,
                column: "CreatedAt",
                value: new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Vehicles",
                keyColumn: "Id",
                keyValue: 5,
                column: "CreatedAt",
                value: new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Vehicles",
                keyColumn: "Id",
                keyValue: 6,
                column: "CreatedAt",
                value: new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Vehicles",
                keyColumn: "Id",
                keyValue: 7,
                column: "CreatedAt",
                value: new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Vehicles",
                keyColumn: "Id",
                keyValue: 8,
                column: "CreatedAt",
                value: new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Vehicles",
                keyColumn: "Id",
                keyValue: 9,
                column: "CreatedAt",
                value: new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Vehicles",
                keyColumn: "Id",
                keyValue: 10,
                column: "CreatedAt",
                value: new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc));
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DeleteData(
                table: "SeasonalPrices",
                keyColumn: "Id",
                keyValue: 3);

            migrationBuilder.DeleteData(
                table: "SeasonalPrices",
                keyColumn: "Id",
                keyValue: 4);

            migrationBuilder.DeleteData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 3);

            migrationBuilder.DeleteData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 4);

            migrationBuilder.DeleteData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 5);

            migrationBuilder.DeleteData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 6);

            migrationBuilder.DeleteData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 7);

            migrationBuilder.DeleteData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 8);

            migrationBuilder.DeleteData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 9);

            migrationBuilder.DeleteData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 10);

            migrationBuilder.DeleteData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 11);

            migrationBuilder.DeleteData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 12);

            migrationBuilder.DeleteData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 13);

            migrationBuilder.DeleteData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 14);

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 1,
                column: "CreatedAt",
                value: new DateTime(2026, 11, 1, 0, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 2,
                column: "CreatedAt",
                value: new DateTime(2026, 11, 1, 0, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Vehicles",
                keyColumn: "Id",
                keyValue: 1,
                column: "CreatedAt",
                value: new DateTime(2026, 11, 1, 0, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Vehicles",
                keyColumn: "Id",
                keyValue: 2,
                column: "CreatedAt",
                value: new DateTime(2026, 11, 1, 0, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Vehicles",
                keyColumn: "Id",
                keyValue: 3,
                column: "CreatedAt",
                value: new DateTime(2026, 11, 1, 0, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Vehicles",
                keyColumn: "Id",
                keyValue: 4,
                column: "CreatedAt",
                value: new DateTime(2026, 11, 1, 0, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Vehicles",
                keyColumn: "Id",
                keyValue: 5,
                column: "CreatedAt",
                value: new DateTime(2026, 11, 1, 0, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Vehicles",
                keyColumn: "Id",
                keyValue: 6,
                column: "CreatedAt",
                value: new DateTime(2026, 11, 1, 0, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Vehicles",
                keyColumn: "Id",
                keyValue: 7,
                column: "CreatedAt",
                value: new DateTime(2026, 11, 1, 0, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Vehicles",
                keyColumn: "Id",
                keyValue: 8,
                column: "CreatedAt",
                value: new DateTime(2026, 11, 1, 0, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Vehicles",
                keyColumn: "Id",
                keyValue: 9,
                column: "CreatedAt",
                value: new DateTime(2026, 11, 1, 0, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.UpdateData(
                table: "Vehicles",
                keyColumn: "Id",
                keyValue: 10,
                column: "CreatedAt",
                value: new DateTime(2026, 11, 1, 0, 0, 0, 0, DateTimeKind.Utc));
        }
    }
}
