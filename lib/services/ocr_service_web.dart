import 'dart:js_interop';

import 'package:image_picker/image_picker.dart';

@JS('formatAnythingRecognize')
external JSPromise<JSString> _recognizeImage(
  JSString imageUrl,
  JSString language,
);

class OcrService {
  static Future<String> recognize(XFile file) async {
    try {
      final text = await _recognizeImage(file.path.toJS, 'eng'.toJS).toDart;
      return text.toDart;
    } catch (error) {
      throw Exception(
        'Browser OCR failed. Check your connection and try a clearer image. '
        'Details: $error',
      );
    }
  }
}
