# Sistem preporuke vozila

Korisnik u mobilnoj aplikaciji dobija do pet preporučenih vozila, svako s kratkim objašnjenjem zašto mu se
preporučuje. Preporuke se računaju na serveru i vraća ih endpoint `GET /Recommendations` (samo za ulogu Korisnik).

Sistem kombinuje tri pristupa:

- **matrična faktorizacija** (Matrix Factorization, ML.NET) – glavni pristup, uči iz historije najmova svih korisnika;
- **preporuka po sadržaju** (content-based) – za vozilo koje model ne može procijeniti;
- **preporuka po popularnosti** (popularity-based) – za korisnika koji još nema nijedan najam.

## Podaci

- Najam je rezervacija sa statusom **Potvrđena** ili **Završena**. Rezervacije na čekanju i otkazane rezervacije
  se ne računaju.
- Podaci nastaju u samoj aplikaciji: korisnik pravi rezervaciju, plaća je, a administrator je potvrđuje i završava.
  Početni podaci sadrže historiju od oko godinu dana najmova.
- Za preporuku se koriste kategorija, gorivo, mjenjač i cijena po danu vozila, te koja je vozila koji korisnik
  iznajmio.

## Matrična faktorizacija

Model uči koja vozila iznajmljuju isti korisnici.

1. Za svaki par vozila A i B računa se udio korisnika koji su iznajmili A, a iznajmili su i B.
   Npr. ako je od 8 korisnika koji su iznajmili Toyotu Yaris njih 6 iznajmilo i Volkswagen Polo, vrijednost para
   (Yaris, Polo) je 6 / 8 = 0,75. Par koji nijedan korisnik nije iznajmio zajedno ima vrijednost 0.
2. Te vrijednosti čine matricu vozilo × vozilo. ML.NET (`Microsoft.ML.Recommender`, `MatrixFactorizationTrainer`)
   je rastavlja na skrivene osobine vozila i iz njih procjenjuje vrijednost svakog para. Postavke: funkcija gubitka
   `SquareLossRegression`, 100 iteracija, regularizacija (`Lambda`) 0,025, jedna nit (isti podaci daju isti model).
3. Za vozilo koje korisnik nije iznajmio uzima se najveća procjena modela preko svih vozila koja je korisnik
   iznajmio. Vozilo preko kojeg je procjena najveća navodi se u objašnjenju.

Procjena je između 0 i 1 i znači koliko je vjerovatno da korisnik koji je iznajmio jedno vozilo iznajmi i drugo.

U modelu se koristi udio korisnika, a ne samo da li je par vozila ikad iznajmljen zajedno. Vozila je malo, pa je
skoro svaki par neki korisnik iznajmio zajedno. Model koji bi znao samo „bilo je zajedno / nije bilo” dao bi
gotovo svim vozilima istu procjenu i ne bi ih mogao poredati.

## Novo vozilo – preporuka po sadržaju

Vozilo koje nije u modelu (niko ga još nije iznajmio zajedno s nekim drugim vozilom) model ne može procijeniti.
Takvo vozilo se poredi s vozilima koja je korisnik iznajmio:

- ista kategorija: 0,4
- isto gorivo: 0,2
- isti mjenjač: 0,2
- cijena po danu: 0,2 × (1 − razlika cijena / veća cijena)

Zbir je sličnost između 0 i 1. Uzima se najsličnije vozilo koje je korisnik iznajmio i ono se navodi u objašnjenju.

Primjer: Hyundai Tucson (SUV, dizel, automatski, 110 KM) i Toyota RAV4 (SUV, hibrid, automatski, 120 KM):
0,4 + 0 + 0,2 + 0,2 × (1 − 10 / 120) ≈ 0,78.

## Novi korisnik – preporuka po popularnosti

Korisnik bez ijednog najma nema podataka na osnovu kojih bi model procijenio njegov interes. Njemu se preporučuju
aktivna vozila s najviše najmova (svih korisnika). Vozilo koje niko nije iznajmio ne preporučuje se kao popularno.

## Kako se biraju preporuke

1. Kandidati su aktivna vozila koja korisnik još nije iznajmio.
2. Ako korisnik nema najam, kandidati se poredaju po broju najmova.
3. Ako ima, svaki kandidat koji je u modelu dobija procjenu modela, a ostali sličnost po sadržaju. Obje vrijednosti
   su između 0 i 1, pa se kandidati poredaju po njima.
4. Vraća se pet kandidata s najvećom vrijednošću. Kod jednake vrijednosti prednost ima vozilo s manjim Id-em.

## Objašnjenja

- Matrična faktorizacija: „Preporučeno na osnovu vašeg najma vozila Toyota Yaris.”
- Po sadržaju: „Slično vozilu Toyota RAV4 koje ste iznajmili.”
- Po popularnosti: „Često iznajmljivano vozilo.”

Uz objašnjenje odgovor sadrži i tip preporuke (`Type`: 1 = matrična faktorizacija, 2 = po sadržaju,
3 = po popularnosti).

## Treniranje, spremanje i ponovno treniranje

- Pozadinski servis (`RecommendationTrainingBackgroundService`) se pokreće sa API-jem i zatim svakih 5 minuta
  provjerava podatke.
- Pri svakoj provjeri čita listu parova (korisnik, vozilo) iz najmova i računa njen SHA-256 sažetak. Ako je sažetak
  isti kao za model koji se koristi, ništa se ne radi.
- Ako se sažetak promijenio (novi najam, potvrđena ili otkazana rezervacija), model se ponovo trenira.
- Istrenirani model se sprema u bazu, u tabelu `RecommendationModels` (model kao binarni zapis, sažetak podataka i
  vrijeme treniranja). Čuva se samo zadnji model.
- Pri pokretanju API-ja učitava se spremljeni model ako je istreniran na istim podacima. Inače se trenira novi.
- Nakon treniranja ili učitavanja model jednom izračuna procjene za sve parove vozila. Procjene se drže u memoriji
  i koriste za svaki zahtjev, bez ponovnog pokretanja modela.

Lista vozila koja je korisnik iznajmio čita se iz baze pri svakom zahtjevu. Zato se novi najam odmah vidi u
preporukama (to vozilo se više ne preporučuje, a korisnik bez najma prelazi s popularnih na lične preporuke).
Procjene modela se osvježe pri sljedećoj provjeri.

## Provjera s početnim podacima

Svi početni korisnici imaju lozinku `test`.

- `mobile`: lične preporuke (matrična faktorizacija) i Hyundai Tucson kao novo vozilo slično Toyoti RAV4.
- `amar.hodzic`, `lejla.hasic`: lične preporuke; Tucson se preporučuje po sličnosti s vozilom koje su iznajmili.
- `tarik.kovacevic`, `dzana.softic`: nemaju nijedan najam, pa dobijaju popularna vozila.
- Hyundai Tucson nikad nije iznajmljen, pa nije u modelu i preporučuje se samo po sadržaju.

Ponovno treniranje se može provjeriti tako da korisnik bez najma (npr. `dzana.softic`) napravi i plati rezervaciju,
a administrator je potvrdi. Preporuke tog korisnika odmah postaju lične, a u logu API-ja se u roku od 5 minuta
pojavi poruka „Trained recommendation model …”.

## Kod

- `RentACar.Services/Implementations/RecommendationService.cs` – izbor i poredak preporuka, objašnjenja
- `RentACar.Services/Implementations/RecommendationTrainingService.cs` – podaci za treniranje, sažetak, spremanje i
  učitavanje modela
- `RentACar.Services/Recommendations/RecommendationModelTrainer.cs` – ML.NET treniranje i procjena parova
- `RentACar.Services/Recommendations/VehicleSimilarity.cs` – sličnost po sadržaju
- `RentACar.WebAPI/BackgroundServices/RecommendationTrainingBackgroundService.cs` – provjera svakih 5 minuta
- `RentACar.WebAPI/Controllers/RecommendationsController.cs` – `GET /Recommendations`
