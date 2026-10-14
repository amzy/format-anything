import 'dart:js' as js;
import 'dart:js_util' as js_util;

import 'package:image_picker/image_picker.dart';

class OcrService {
  static Future<String> recognize(XFile file) async {
    final tesseract = js.context['Tesseract'];
    if (tesseract == null) {
      throw Exception(
        'The browser OCR engine could not load. Check your internet connection and try again.',
      );
    }

    // Tesseract.js fetches the selected image URL and runs OCR in WebAssembly.
    final promise = js_util.callMethod<Object?>(
      tesseract,
      'recognize',
      <Object?>[file.path, 'eng'],
    );
    final result = await js_util.promiseToFuture<Object?>(promise);
    if (result == null) return '';
    final data = js_util.getProperty<Object?>(result, 'data');
    if (data == null) return '';
    return js_util.getProperty<String?>(data, 'text') ?? '';
  }
}
