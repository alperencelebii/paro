import 'package:equatable/equatable.dart';
import '../data/models/invoice_model.dart';
import 'dart:io';

/// States for the ScannerBloc
abstract class ScannerState extends Equatable {
  const ScannerState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ScannerInitial extends ScannerState {
  const ScannerInitial();
}

/// Requesting permissions
class ScannerRequestingPermissions extends ScannerState {
  const ScannerRequestingPermissions();
}

/// Permissions denied
class ScannerPermissionsDenied extends ScannerState {
  final String message;

  const ScannerPermissionsDenied({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Loading camera
class ScannerLoadingCamera extends ScannerState {
  const ScannerLoadingCamera();
}

/// Image captured
class ScannerCaptured extends ScannerState {
  final File image;
  final String source;

  const ScannerCaptured({
    required this.image,
    required this.source,
  });

  @override
  List<Object?> get props => [image, source];
}

/// Cropping state
class ScannerCropping extends ScannerState {
  final File image;

  const ScannerCropping({required this.image});

  @override
  List<Object?> get props => [image];
}

/// Processing OCR
class ScannerProcessing extends ScannerState {
  final double? progress;
  final String? message;

  const ScannerProcessing({
    this.progress,
    this.message,
  });

  @override
  List<Object?> get props => [progress, message];
}

/// OCR completed and parsed
class ScannerParsed extends ScannerState {
  final InvoiceModel invoice;
  final Map<String, double> confidenceScores;

  const ScannerParsed({
    required this.invoice,
    required this.confidenceScores,
  });

  @override
  List<Object?> get props => [invoice, confidenceScores];
}

/// Error state
class ScannerError extends ScannerState {
  final String message;
  final bool canRetry;

  const ScannerError({
    required this.message,
    this.canRetry = true,
  });

  @override
  List<Object?> get props => [message, canRetry];
}

/// Invoice saved successfully
class ScannerSaved extends ScannerState {
  final bool success;
  final String? expenseId;
  final String? errorMessage;

  const ScannerSaved({
    required this.success,
    this.expenseId,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [success, expenseId, errorMessage];
}

