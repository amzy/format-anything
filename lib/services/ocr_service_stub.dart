import 'package:image_picker/image_picker.dart';

class OcrService {
  static Future<String> recognize(XFile file) async {
    throw UnsupportedError('OCR is not supported on this platform.');
  }
}
