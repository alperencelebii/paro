import 'dart:async';
import 'dart:developer' as dev;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'connectivity_state.dart';

/// Cubit to manage connectivity status
class ConnectivityCubit extends Cubit<ConnectivityState> {
  final Connectivity _connectivity;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  /// Constructor
  ConnectivityCubit({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity(),
        super(const ConnectivityState.loading()) {
    _init();
  }

  /// Initialize the cubit and start listening to connectivity changes
  Future<void> _init() async {
    try {
      // Check initial connectivity
      final initialResults = await _connectivity.checkConnectivity();
      _updateConnectivityStatus(initialResults);

      // Listen for connectivity changes
      _connectivitySubscription =
          _connectivity.onConnectivityChanged.listen((results) {
        _updateConnectivityStatus(results);
      });

      dev.log('ConnectivityCubit initialized');
    } catch (e) {
      dev.log('Error initializing ConnectivityCubit: $e');
      emit(const ConnectivityState.unknown(
          errorMessage: 'Failed to initialize connectivity monitoring'));
    }
  }

  /// Update connectivity status based on connectivity results
  void _updateConnectivityStatus(List<ConnectivityResult> results) {
    // Handle empty list
    if (results.isEmpty) {
      emit(const ConnectivityState.disconnected());
      return;
    }

    // Filter out 'none' results - if all are none, device is disconnected
    final activeConnections = results
        .where(
          (result) => result != ConnectivityResult.none,
        )
        .toList();

    if (activeConnections.isEmpty) {
      dev.log('Connectivity changed: disconnected');
      emit(const ConnectivityState.disconnected());
    } else {
      // Use the first active connection type
      final primaryConnection = activeConnections.first;
      dev.log('Connectivity changed: ${primaryConnection.name}');
      emit(ConnectivityState.connected(
        connectionType: primaryConnection.name,
      ));
    }
  }

  /// Check if device is currently connected
  bool get isConnected => state.status == ConnectivityStatus.connected;

  /// Get connection type if connected
  String get connectionType => state.connectionType ?? 'none';

  /// Close any open subscriptions
  @override
  Future<void> close() {
    _connectivitySubscription.cancel();
    return super.close();
  }
}
