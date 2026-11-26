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
   migracije i početni podaci, uključujući slike vozila i korisnika te historiju rezervacija. Pregled RabbitMQ redova je na `http://localhost:15672`
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
Ostali početni korisnici (npr. `amar.hodzic`) također imaju lozinku `test`.

## Sistem preporuke

Opis sistema preporuke vozila (podaci, algoritmi, objašnjenja i ponovno treniranje modela) je u
[recommender-dokumentacija.md](recommender-dokumentacija.md).

## Izvori slika

Slike vozila u početnim podacima (`RentACar/RentACar.Services/Database/SeedImages`) su fotografije s Wikimedia
Commonsa. Svaka je izrezana i smanjena na 800 × 500 px, a na slikama 3, 4, 5, 7, 9 i 10 zamućena je registarska
tablica. Izmijenjene slike ostaju pod licencom originala.

- `vehicle-1.jpg`, Volkswagen Golf VIII: Alexander Migl, [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/),
  [original](https://commons.wikimedia.org/wiki/File:Volkswagen_Golf_VIII_IMG_2609.jpg)
- `vehicle-2.jpg`, Škoda Octavia IV: Mike-fiesta, [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/),
  [original](https://commons.wikimedia.org/wiki/File:Skoda_Octavia_IV_liftback.jpg)
- `vehicle-3.jpg`, Toyota RAV4 Hybrid: Alexander Migl, [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/),
  [original](https://commons.wikimedia.org/wiki/File:Toyota_RAV4_Hybrid_(XA50)_DSC_2709.jpg)
- `vehicle-4.jpg`, Renault Clio V: Alexander Migl, [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/),
  [original](https://commons.wikimedia.org/wiki/File:Renault_Clio_V_1X7A0393.jpg)
- `vehicle-5.jpg`, Dacia Duster II: Calreyn88, [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/),
  [original](https://commons.wikimedia.org/wiki/File:2022_Dacia_Duster_Extreme_SE_TC2_4X2_Auto.jpg)
- `vehicle-6.jpg`, Volkswagen Polo VI: Alexander Migl, [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/),
  [original](https://commons.wikimedia.org/wiki/File:Volkswagen_Polo_VI_R-Line_(2021)_Auto_Zuerich_2021_IMG_0217.jpg)
- `vehicle-7.jpg`, Volkswagen Passat Variant B8: Charles from Port Chester, New York,
  [CC BY 2.0](https://creativecommons.org/licenses/by/2.0/),
  [original](https://commons.wikimedia.org/wiki/File:Volkswagen_Passat_Variant_2.0_TDI_(2023)_(53464656956).jpg)
- `vehicle-8.jpg`, Toyota Yaris Hybrid: Alexander Migl, [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/),
  [original](https://commons.wikimedia.org/wiki/File:Toyota_Yaris_Hybrid_(XP210)_IMG_4209.jpg)
- `vehicle-9.jpg`, Hyundai Tucson: Alexander-93, [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/),
  [original](https://commons.wikimedia.org/wiki/File:Hyundai_Tucson_(NX4,_SWB)_Facelift_IMG_2344.jpg)
- `vehicle-10.jpg`, Škoda Fabia IV: Alexander Migl, [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/),
  [original](https://commons.wikimedia.org/wiki/File:Skoda_Fabia_IV_1X7A0388.jpg)
