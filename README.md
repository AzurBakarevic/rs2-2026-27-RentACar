# RentACar

Seminarski rad iz predmeta Razvoj softvera II: sistem za iznajmljivanje vozila.
Backend je .NET 10 Web API sa SQL Serverom; desktop (administracija) i mobilna aplikacija (korisnici) rade se u Flutteru.

## Pokretanje

Potrebno: .NET 10 SDK i Docker Desktop.

1. Raspakovati `.env` iz arhive `.env-tajne.zip` (šifra je na DL-u) u folder `RentACar/`, pored `docker-compose.yml`.
   Fajl `.env` nije u repozitoriju; u njemu je sva konfiguracija (baza, JWT).
2. Pokrenuti bazu (SQL Server u Dockeru):

   ```
   cd RentACar
   docker compose up -d
   ```

3. Pokrenuti API (iz istog foldera):

   ```
   dotnet run --project RentACar.WebAPI
   ```

   API radi na `http://localhost:5001`. Pri pokretanju se automatski primjenjuju migracije i početni podaci,
   uključujući slike vozila. Dokumentacija API-ja (Scalar) je u Development okruženju na `http://localhost:5001/scalar`.

Desktop i mobilna aplikacija su u izradi; upute za njihovo pokretanje bit će dodane kad budu gotove.

## Pristupni podaci

| Kontekst | Korisničko ime | Lozinka | Uloga |
|---|---|---|---|
| Desktop verzija | desktop | test | Administrator |
| Mobilna verzija | mobile | test | Korisnik |

Sistem ima dvije uloge: Administrator (desktop aplikacija) i Korisnik (mobilna aplikacija).
