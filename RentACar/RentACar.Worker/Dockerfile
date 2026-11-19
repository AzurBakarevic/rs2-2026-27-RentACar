# Worker je poseban projekat i poseban kontejner (upute 3.2). Gradi se iz foldera RentACar (context u docker-compose.yml).
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Prvo samo projektni fajlovi: paketi se ponovo preuzimaju samo kad se oni promijene.
COPY RentACar.Model/RentACar.Model.csproj RentACar.Model/
COPY RentACar.Worker/RentACar.Worker.csproj RentACar.Worker/
RUN dotnet restore RentACar.Worker/RentACar.Worker.csproj

COPY RentACar.Model/ RentACar.Model/
COPY RentACar.Worker/ RentACar.Worker/
RUN dotnet publish RentACar.Worker/RentACar.Worker.csproj -c Release -o /app/publish --no-restore -p:UseAppHost=false

# Worker ne treba ASP.NET, pa je dovoljan runtime image.
FROM mcr.microsoft.com/dotnet/runtime:10.0 AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "RentACar.Worker.dll"]
