part of 'privacy_security_bloc.dart';

/// Enum for export data format
enum ExportFormat { csv, json }

/// State for the privacy and security settings
class PrivacySecurityState {
  /// Whether biometric authentication is enabled
  final bool biometricEnabled;

  /// Whether data analytics consent is given
  final bool dataAnalyticsConsent;

  /// Whether data sync is enabled
  final bool dataSyncEnabled;

  /// Whether encryption is enabled
  final bool encryptionEnabled;

  /// Whether the settings are being loaded
  final bool isLoading;

  /// Whether the settings are loaded
  final bool settingsLoaded;

  /// Whether data processing is in progress
  final bool isProcessing;

  /// Whether data export is in progress
  final bool isExporting;

  /// Format for data export
  final ExportFormat? exportFormat;

  /// Error message, if any
  final String? error;

  /// Success message, if any
  final String? successMessage;

  /// Create an instance of [PrivacySecurityState]
  const PrivacySecurityState({
    this.biometricEnabled = false,
    this.dataAnalyticsConsent = true,
    this.dataSyncEnabled = true,
    this.encryptionEnabled = true,
    this.isLoading = false,
    this.settingsLoaded = false,
    this.isProcessing = false,
    this.isExporting = false,
    this.exportFormat,
    this.error,
    this.successMessage,
  });

  /// Create a copy of the current state with specified fields replaced
  PrivacySecurityState copyWith({
    bool? biometricEnabled,
    bool? dataAnalyticsConsent,
    bool? dataSyncEnabled,
    bool? encryptionEnabled,
    bool? isLoading,
    bool? settingsLoaded,
    bool? isProcessing,
    bool? isExporting,
    ExportFormat? exportFormat,
    String? error,
    String? successMessage,
  }) {
    return PrivacySecurityState(
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      dataAnalyticsConsent: dataAnalyticsConsent ?? this.dataAnalyticsConsent,
      dataSyncEnabled: dataSyncEnabled ?? this.dataSyncEnabled,
      encryptionEnabled: encryptionEnabled ?? this.encryptionEnabled,
      isLoading: isLoading ?? this.isLoading,
      settingsLoaded: settingsLoaded ?? this.settingsLoaded,
      isProcessing: isProcessing ?? this.isProcessing,
      isExporting: isExporting ?? this.isExporting,
      exportFormat: exportFormat ?? this.exportFormat,
      error: error, // intentionally overwrite with null if not provided
      successMessage:
          successMessage, // intentionally overwrite with null if not provided
    );
  }
}
