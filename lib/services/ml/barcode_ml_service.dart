import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class BarcodeMlService {
  static Future<List<String>> scanFromFile(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final scanner = BarcodeScanner();
    try {
      final barcodes = await scanner.processImage(inputImage);
      return barcodes
          .map((b) => b.rawValue ?? '')
          .where((v) => v.isNotEmpty)
          .toList();
    } finally {
      scanner.close();
    }
  }
}
