FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY RentACar.Model/RentACar.Model.csproj RentACar.Model/
COPY RentACar.Services/RentACar.Services.csproj RentACar.Services/
COPY RentACar.WebAPI/RentACar.WebAPI.csproj RentACar.WebAPI/
RUN dotnet restore RentACar.WebAPI/RentACar.WebAPI.csproj

COPY RentACar.Model/ RentACar.Model/
COPY RentACar.Services/ RentACar.Services/
COPY RentACar.WebAPI/ RentACar.WebAPI/
RUN dotnet publish RentACar.WebAPI/RentACar.WebAPI.csproj -c Release -o /app/publish --no-restore -p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app
COPY --from=build /app/publish .
EXPOSE 8080
ENTRYPOINT ["dotnet", "RentACar.WebAPI.dll"]
