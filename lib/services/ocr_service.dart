export 'ocr_service_stub.dart'
    if (dart.library.html) 'ocr_service_web.dart'
    if (dart.library.io) 'ocr_service_native.dart';
