import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageCompressionService {
  const ImageCompressionService._();

  static Future<Uint8List> compressFile(File file) async {
    final originalBytes = await file.readAsBytes();
    try {
      final compressedBytes = await FlutterImageCompress.compressWithList(
        originalBytes,
        minWidth: 400,
        minHeight: 400,
        quality: 70,
      );
      return compressedBytes.isEmpty ? originalBytes : compressedBytes;
    } catch (error) {
      debugPrint('Image compression failed: $error');
      return originalBytes;
    }
  }
}
