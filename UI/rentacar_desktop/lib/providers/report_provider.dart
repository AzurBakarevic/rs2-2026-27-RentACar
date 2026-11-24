import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/report.dart';
import '../utils/api_client_exception.dart';
import '../utils/formatters.dart';
import 'base_provider.dart';

class ReportProvider with ChangeNotifier {
  static final RegExp _fileNamePattern = RegExp(r'filename="?([^";]+)"?');

  Future<ReportFile> generate(ReportType type, DateTime from, DateTime to) async {
    final uri = BaseProvider.buildUri('Reports/${type.apiName}', {'from': toApiDate(from), 'to': toApiDate(to)});
    final response = await BaseProvider.send(() => http.get(uri, headers: BaseProvider.createHeaders()));

    final bytes = response.bodyBytes;
    if (!(response.headers['content-type'] ?? '').startsWith('application/pdf') || bytes.isEmpty) {
      throw ApiClientException('Odgovor servera nije moguće pročitati.');
    }

    final fileName = _fileNamePattern.firstMatch(response.headers['content-disposition'] ?? '')?.group(1)?.trim();
    return ReportFile(
      bytes: bytes,
      fileName: fileName == null || fileName.isEmpty
          ? 'izvjestaj_${toApiDate(from)}_${toApiDate(to)}.pdf'
          : fileName,
    );
  }
}
