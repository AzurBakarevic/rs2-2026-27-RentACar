import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

const double _printDpi = 200;
const double _sizeTolerance = 2;

Future<bool> printPdf(Uint8List bytes, String name) async {
  final firstPage = await Printing.raster(bytes, pages: [0]).first;
  final documentFormat = PdfPageFormat(firstPage.width.toDouble(), firstPage.height.toDouble());
  return Printing.layoutPdf(
    onLayout: (paperFormat) => _fitToPaper(bytes, documentFormat, paperFormat),
    name: name,
    format: documentFormat,
    windowsModernDialog: true,
  );
}

Future<Uint8List> _fitToPaper(Uint8List bytes, PdfPageFormat documentFormat, PdfPageFormat paperFormat) async {
  if ((documentFormat.width - paperFormat.width).abs() <= _sizeTolerance &&
      (documentFormat.height - paperFormat.height).abs() <= _sizeTolerance) {
    return bytes;
  }

  final areaWidth = paperFormat.availableWidth;
  final areaHeight = paperFormat.availableHeight;
  final document = pw.Document();
  await for (final page in Printing.raster(bytes, dpi: _printDpi)) {
    final width = page.width * PdfPageFormat.inch / _printDpi;
    final height = page.height * PdfPageFormat.inch / _printDpi;
    final rotate = (width > height) != (areaWidth > areaHeight);
    final scale = rotate
        ? math.min(areaWidth / height, areaHeight / width)
        : math.min(areaWidth / width, areaHeight / height);
    final image = pw.SizedBox(
      width: width * scale,
      height: height * scale,
      child: pw.Image(pw.RawImage(bytes: page.pixels, width: page.width, height: page.height)),
    );
    document.addPage(
      pw.Page(
        pageFormat: paperFormat,
        build: (_) => pw.Center(
          child: rotate ? pw.Transform.rotateBox(angle: math.pi / 2, unconstrained: true, child: image) : image,
        ),
      ),
    );
  }
  return document.save();
}
