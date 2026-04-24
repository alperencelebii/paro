import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as dev;

part 'privacy_security_event.dart';
part 'privacy_security_state.dart';

/// BLoC for managing privacy and security settings
class PrivacySecurityBloc
    extends Bloc<PrivacySecurityEvent, PrivacySecurityState> {
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _dataAnalyticsConsentKey = 'data_analytics_consent';
  static const String _dataSyncEnabledKey = 'data_sync_enabled';
  static const String _encryptionEnabledKey = 'encryption_enabled';

  PrivacySecurityBloc() : super(const PrivacySecurityState()) {
    on<LoadPrivacySecuritySettings>(_onLoadPrivacySecuritySettings);
    on<ToggleBiometricAuthentication>(_onToggleBiometricAuthentication);
    on<ToggleDataAnalyticsConsent>(_onToggleDataAnalyticsConsent);
    on<ToggleDataSyncEnabled>(_onToggleDataSyncEnabled);
    on<ToggleEncryptionEnabled>(_onToggleEncryptionEnabled);
    on<RequestDataDeletion>(_onRequestDataDeletion);
    on<ExportData>(_onExportData);
  }

  /// Handler for loading privacy and security settings
  Future<void> _onLoadPrivacySecuritySettings(
    LoadPrivacySecuritySettings event,
    Emitter<PrivacySecurityState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final prefs = await SharedPreferences.getInstance();

      final biometricEnabled = prefs.getBool(_biometricEnabledKey) ?? false;
      final dataAnalyticsConsent =
          prefs.getBool(_dataAnalyticsConsentKey) ?? true;
      final dataSyncEnabled = prefs.getBool(_dataSyncEnabledKey) ?? true;
      final encryptionEnabled = prefs.getBool(_encryptionEnabledKey) ?? true;

      emit(state.copyWith(
        biometricEnabled: biometricEnabled,
        dataAnalyticsConsent: dataAnalyticsConsent,
        dataSyncEnabled: dataSyncEnabled,
        encryptionEnabled: encryptionEnabled,
        isLoading: false,
        settingsLoaded: true,
      ));
    } catch (e) {
      dev.log('Error loading privacy settings: $e');
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to load settings: ${e.toString()}',
      ));
    }
  }

  /// Handler for toggling biometric authentication
  Future<void> _onToggleBiometricAuthentication(
    ToggleBiometricAuthentication event,
    Emitter<PrivacySecurityState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricEnabledKey, event.enabled);
      emit(state.copyWith(
        biometricEnabled: event.enabled,
        successMessage:
            'Biometric authentication ${event.enabled ? 'enabled' : 'disabled'}',
      ));

      // Clear success message after some time
      await Future.delayed(const Duration(seconds: 3));
      if (!isClosed) {
        emit(state.copyWith(successMessage: null));
      }
    } catch (e) {
      dev.log('Error toggling biometric authentication: $e');
      emit(state.copyWith(error: 'Failed to update biometric settings'));
    }
  }

  /// Handler for toggling data analytics consent
  Future<void> _onToggleDataAnalyticsConsent(
    ToggleDataAnalyticsConsent event,
    Emitter<PrivacySecurityState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_dataAnalyticsConsentKey, event.enabled);
      emit(state.copyWith(
        dataAnalyticsConsent: event.enabled,
        successMessage:
            'Analytics consent ${event.enabled ? 'enabled' : 'disabled'}',
      ));

      // Clear success message after some time
      await Future.delayed(const Duration(seconds: 3));
      if (!isClosed) {
        emit(state.copyWith(successMessage: null));
      }
    } catch (e) {
      dev.log('Error toggling data analytics consent: $e');
      emit(state.copyWith(error: 'Failed to update analytics settings'));
    }
  }

  /// Handler for toggling data sync
  Future<void> _onToggleDataSyncEnabled(
    ToggleDataSyncEnabled event,
    Emitter<PrivacySecurityState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_dataSyncEnabledKey, event.enabled);
      emit(state.copyWith(
        dataSyncEnabled: event.enabled,
        successMessage:
            'Data synchronization ${event.enabled ? 'enabled' : 'disabled'}',
      ));

      // Clear success message after some time
      await Future.delayed(const Duration(seconds: 3));
      if (!isClosed) {
        emit(state.copyWith(successMessage: null));
      }
    } catch (e) {
      dev.log('Error toggling data sync: $e');
      emit(state.copyWith(error: 'Failed to update sync settings'));
    }
  }

  /// Handler for toggling encryption
  Future<void> _onToggleEncryptionEnabled(
    ToggleEncryptionEnabled event,
    Emitter<PrivacySecurityState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_encryptionEnabledKey, event.enabled);
      emit(state.copyWith(
        encryptionEnabled: event.enabled,
        successMessage:
            'Data encryption ${event.enabled ? 'enabled' : 'disabled'}',
      ));

      // Clear success message after some time
      await Future.delayed(const Duration(seconds: 3));
      if (!isClosed) {
        emit(state.copyWith(successMessage: null));
      }
    } catch (e) {
      dev.log('Error toggling encryption: $e');
      emit(state.copyWith(error: 'Failed to update encryption settings'));
    }
  }

  /// Handler for data deletion request
  Future<void> _onRequestDataDeletion(
    RequestDataDeletion event,
    Emitter<PrivacySecurityState> emit,
  ) async {
    emit(state.copyWith(isProcessing: true));
    try {
      // Simulate data deletion process
      await Future.delayed(const Duration(seconds: 2));

      emit(state.copyWith(
        isProcessing: false,
        successMessage: 'Data deletion request submitted successfully',
      ));

      // Clear success message after some time
      await Future.delayed(const Duration(seconds: 3));
      if (!isClosed) {
        emit(state.copyWith(successMessage: null));
      }
    } catch (e) {
      dev.log('Error requesting data deletion: $e');
      emit(state.copyWith(
        isProcessing: false,
        error: 'Failed to submit data deletion request',
      ));
    }
  }

  /// Handler for exporting data
  Future<void> _onExportData(
    ExportData event,
    Emitter<PrivacySecurityState> emit,
  ) async {
    emit(state.copyWith(isProcessing: true));
    try {
      // The actual export logic will be handled by the screen using the export service
      emit(state.copyWith(
        isProcessing: false,
        isExporting: true,
        exportFormat: event.isJson ? ExportFormat.json : ExportFormat.csv,
      ));

      // Reset export flags after processing is done in the UI
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!isClosed) {
          emit(state.copyWith(isExporting: false, exportFormat: null));
        }
      });
    } catch (e) {
      dev.log('Error preparing data export: $e');
      emit(state.copyWith(
        isProcessing: false,
        error: 'Failed to prepare data for export',
      ));
    }
  }
}
