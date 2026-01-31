// Jobs v2 - Image Utilities
// Client-side image compression for profile photos

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Maximum dimension for profile photos (1080p)
const int maxDimension = 1080;

/// JPEG quality (70% provides good balance of quality/size)
const int jpegQuality = 70;

/// Pick and compress an image from the gallery or camera
/// Returns compressed JPEG bytes, or null if cancelled/failed
Future<Uint8List?> pickAndCompressImage({
  ImageSource source = ImageSource.gallery,
}) async {
  try {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: source,
      maxWidth: maxDimension.toDouble(),
      maxHeight: maxDimension.toDouble(),
    );

    if (picked == null) return null;

    // Read original bytes
    final Uint8List originalBytes = await picked.readAsBytes();

    // Compress using flutter_image_compress
    // This provides consistent compression across iOS, Android, and Web
    final Uint8List compressed = await FlutterImageCompress.compressWithList(
      originalBytes,
      minWidth: maxDimension,
      minHeight: maxDimension,
      quality: jpegQuality,
      format: CompressFormat.jpeg,
    );

    debugPrint('[ImageUtils] Original: ${originalBytes.length} bytes');
    debugPrint('[ImageUtils] Compressed: ${compressed.length} bytes');
    debugPrint(
        '[ImageUtils] Reduction: ${((1 - compressed.length / originalBytes.length) * 100).toStringAsFixed(1)}%');

    return compressed;
  } catch (e) {
    debugPrint('[ImageUtils] Error picking/compressing image: $e');
    return null;
  }
}

/// Pick multiple images from gallery (max 10), compress each to JPEG
/// Returns list of compressed JPEG bytes
Future<List<Uint8List>> pickMultipleImages({int maxImages = 10}) async {
  try {
    final picker = ImagePicker();
    final List<XFile> picked = await picker.pickMultiImage(
      maxWidth: maxDimension.toDouble(),
      maxHeight: maxDimension.toDouble(),
    );

    if (picked.isEmpty) return [];

    // Limit to max images
    final toProcess = picked.take(maxImages).toList();
    List<Uint8List> compressed = [];

    for (final file in toProcess) {
      final Uint8List bytes = await file.readAsBytes();
      final Uint8List result = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: maxDimension,
        minHeight: maxDimension,
        quality: jpegQuality,
        format: CompressFormat.jpeg,
      );
      compressed.add(result);
      debugPrint(
          '[ImageUtils] Compressed image: ${bytes.length} -> ${result.length} bytes');
    }

    return compressed;
  } catch (e) {
    debugPrint('[ImageUtils] Error picking multiple images: $e');
    return [];
  }
}
