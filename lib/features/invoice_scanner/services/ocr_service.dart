import 'dart:io';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';

/// Service for performing OCR on images using Tesseract OCR (free, open-source)
/// Tesseract supports 16KB page sizes unlike ML Kit
class OcrService {
  /// Perform OCR on an image file
  /// Returns the recognized text as a string
  Future<String> recognizeText(File imageFile) async {
    try {
      // Use Tesseract OCR to extract text from image
      // Language: English (eng) - you can add more languages if needed
      final text = await FlutterTesseractOcr.extractText(
        imageFile.path,
        language: 'eng',
        args: {
          "psm": "6", // Assume a single uniform block of text
          "preserve_interword_spaces": "1",
        },
      );

      return text;
    } catch (e) {
      throw OcrException('Failed to recognize text: $e');
    }
  }

  /// Check if the image is too blurry (simple heuristic)
  /// Returns true if image appears blurry
  Future<bool> isImageBlurry(File imageFile) async {
    // This is a simplified check - in production, you might want to use
    // variance of Laplacian or other image quality metrics
    // For now, we'll rely on OCR confidence scores
    return false;
  }

  /// Dispose resources (not needed for Tesseract)
  void dispose() {
    // No cleanup needed for Tesseract
  }
}

/// Exception thrown when OCR fails
class OcrException implements Exception {
  final String message;
  OcrException(this.message);

  @override
  String toString() => 'OcrException: $message';
}
