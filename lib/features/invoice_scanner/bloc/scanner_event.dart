import 'package:equatable/equatable.dart';
import 'dart:io';

/// Events for the ScannerBloc
abstract class ScannerEvent extends Equatable {
  const ScannerEvent();

  @override
  List<Object?> get props => [];
}

/// Event to start the scanner flow
class ScannerStarted extends ScannerEvent {
  const ScannerStarted();
}

/// Event when an image is picked (from camera or gallery)
class ImagePicked extends ScannerEvent {
  final File image;
  final String source; // 'camera' or 'gallery'

  const ImagePicked({
    required this.image,
    required this.source,
  });

  @override
  List<Object?> get props => [image, source];
}

/// Event when image is cropped
class ImageCropped extends ScannerEvent {
  final File croppedImage;

  const ImageCropped({required this.croppedImage});

  @override
  List<Object?> get props => [croppedImage];
}

/// Event to run OCR on the image
class RunOcr extends ScannerEvent {
  final File image;

  const RunOcr({required this.image});

  @override
  List<Object?> get props => [image];
}

/// Event when OCR is completed and parsing should happen
class OcrCompleted extends ScannerEvent {
  final dynamic ocrResult; // RecognizedText from ML Kit
  final File image;

  const OcrCompleted({
    required this.ocrResult,
    required this.image,
  });

  @override
  List<Object?> get props => [ocrResult, image];
}

/// Event to edit a field
class FieldEdited extends ScannerEvent {
  final String fieldKey;
  final dynamic newValue;

  const FieldEdited({
    required this.fieldKey,
    required this.newValue,
  });

  @override
  List<Object?> get props => [fieldKey, newValue];
}

/// Event to save the invoice as an expense
class SaveInvoice extends ScannerEvent {
  const SaveInvoice();
}

/// Event to retry the scan
class RetryScan extends ScannerEvent {
  const RetryScan();
}

/// Event to cancel the scan
class CancelScan extends ScannerEvent {
  const CancelScan();
}

/// Event when permissions are requested
class RequestPermissions extends ScannerEvent {
  const RequestPermissions();
}

