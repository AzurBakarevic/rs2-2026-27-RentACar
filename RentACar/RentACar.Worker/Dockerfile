FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY RentACar.Model/RentACar.Model.csproj RentACar.Model/
COPY RentACar.Worker/RentACar.Worker.csproj RentACar.Worker/
RUN dotnet restore RentACar.Worker/RentACar.Worker.csproj

COPY RentACar.Model/ RentACar.Model/
COPY RentACar.Worker/ RentACar.Worker/
RUN dotnet publish RentACar.Worker/RentACar.Worker.csproj -c Release -o /app/publish --no-restore -p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/runtime:10.0 AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "RentACar.Worker.dll"]
