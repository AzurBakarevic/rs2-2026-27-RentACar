# RentACar

Seminarski rad iz predmeta Razvoj softvera II: sistem za iznajmljivanje vozila.
Backend je .NET 10 Web API sa SQL Serverom i pomoćnim servisom (Worker) koji preko RabbitMQ-a prima poruke i šalje
e-mailove; desktop (administracija) i mobilna aplikacija (korisnici) rade se u Flutteru.

## Pokretanje

Potrebno: Docker Desktop.

1. Raspakovati `.env` iz arhive `.env-tajne.zip` (šifra je na DL-u) u folder `RentACar/`, pored `docker-compose.yml`.
   Fajl `.env` nije u repozitoriju; u njemu je sva konfiguracija (baza, JWT, Stripe, RabbitMQ, SMTP).
2. Pokrenuti sve servise:

   ```
   cd RentACar
   docker compose up -d --build
   ```

   Pokreću se četiri kontejnera: SQL Server (`rentacar-sql`), RabbitMQ (`rentacar-rabbitmq`), API (`rentacar-api`)
   i Worker (`rentacar-worker`). API radi na `http://localhost:5001`. Pri pokretanju se automatski primjenjuju
   migracije i početni podaci, uključujući slike vozila. Pregled RabbitMQ redova je na `http://localhost:15672`
   (korisnik i lozinka su `RabbitMQ__Username` i `RabbitMQ__Password` iz `.env`).

E-mail (potvrda i otkazivanje rezervacije, kod za reset lozinke) Worker šalje preko SMTP servera iz `.env`.
Početni korisnici imaju izmišljene e-mail adrese, pa se reset lozinke provjerava s korisnikom registrovanim
sa stvarnom adresom.

### Pokretanje API-ja i Worker-a bez Dockera (razvoj)

Potreban je i .NET 10 SDK. U Dockeru se pokreću samo baza i RabbitMQ, a API i Worker iz foldera `RentACar`:

```
docker compose up -d rentacar-sql rentacar-rabbitmq
dotnet run --project RentACar.WebAPI
dotnet run --project RentACar.Worker
```

Dokumentacija API-ja (Scalar) je tada (Development okruženje) na `http://localhost:5001/scalar`.

Desktop i mobilna aplikacija su u izradi; upute za njihovo pokretanje bit će dodane kad budu gotove.

## Pristupni podaci

| Kontekst | Korisničko ime | Lozinka | Uloga |
|---|---|---|---|
| Desktop verzija | desktop | test | Administrator |
| Mobilna verzija | mobile | test | Korisnik |

Sistem ima dvije uloge: Administrator (desktop aplikacija) i Korisnik (mobilna aplikacija).
