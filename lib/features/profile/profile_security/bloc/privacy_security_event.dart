part of 'privacy_security_bloc.dart';

/// Base class for all privacy and security events
abstract class PrivacySecurityEvent {
  const PrivacySecurityEvent();
}

/// Event to load privacy and security settings
class LoadPrivacySecuritySettings extends PrivacySecurityEvent {
  const LoadPrivacySecuritySettings();
}

/// Event to toggle biometric authentication
class ToggleBiometricAuthentication extends PrivacySecurityEvent {
  final bool enabled;

  const ToggleBiometricAuthentication({required this.enabled});
}

/// Event to toggle data analytics consent
class ToggleDataAnalyticsConsent extends PrivacySecurityEvent {
  final bool enabled;

  const ToggleDataAnalyticsConsent({required this.enabled});
}

/// Event to toggle data sync
class ToggleDataSyncEnabled extends PrivacySecurityEvent {
  final bool enabled;

  const ToggleDataSyncEnabled({required this.enabled});
}

/// Event to toggle encryption
class ToggleEncryptionEnabled extends PrivacySecurityEvent {
  final bool enabled;

  const ToggleEncryptionEnabled({required this.enabled});
}

/// Event to request data deletion
class RequestDataDeletion extends PrivacySecurityEvent {
  const RequestDataDeletion();
}

/// Event to export data
class ExportData extends PrivacySecurityEvent {
  final bool isJson;

  const ExportData({required this.isJson});
}
