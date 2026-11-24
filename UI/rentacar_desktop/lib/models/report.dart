import 'dart:typed_data';

enum ReportType {
  reservations('Reservations', 'Rezervacije i prihod po periodu',
      'Generiši PDF izvještaj sa rezervacijama i prihodom u odabranom periodu'),
  mostRentedVehicles('MostRentedVehicles', 'Najčešće iznajmljivana vozila',
      'Generiši PDF izvještaj sa vozilima po broju rezervacija u odabranom periodu');

  const ReportType(this.apiName, this.title, this.description);

  final String apiName;
  final String title;
  final String description;
}

class ReportFile {
  const ReportFile({required this.bytes, required this.fileName});

  final Uint8List bytes;
  final String fileName;
}
