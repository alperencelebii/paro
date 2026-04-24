//
// ignore_for_file: avoid_catches_without_on_clauses

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:user_repository/user_repository.dart';

import '../services/data_clearing_service.dart';
import '../services/auth_service.dart';
import '../router/auth_route_listener.dart' show isDataLoadingTriggered;

part 'app_events.dart';
part 'app_state.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc({required User user, required UserRepository userRepository})
      : _userRepository = userRepository,
        super(
          user.isAnonymous
              ? const AppState.unauthenticated()
              : AppState.authenticated(user),
        ) {
    on<AppUserChanged>(_appUserChanged);
    on<AppLogoutRequested>(_logoutRequested);
    on<AppUpdateAccountRequested>(_appUpdateAccountRequested);
    on<AppDeleteAccountRequested>(_appDeleteAccountRequested);
    on<AppEmailUpdateRequest>(_appEmailUpdateRequest);
    on<AppSetFirstTime>(_appSetFirstTime);
    on<AppDataLoading>(_appDataLoading);
    on<AppDataLoaded>(_appDataLoaded);
    on<AppDataLoadingError>(_appDataLoadingError);
    _userSubscription =
        _userRepository.user.listen(_userChanged, onError: addError);
  }

  /// The current user from the [UserRepository]
  StreamSubscription<User>? _userSubscription;
  final UserRepository _userRepository;
  void _userChanged(User user) => add(AppUserChanged(user));

  FutureOr<void> _appUserChanged(
    AppUserChanged event,
    Emitter<AppState> emit,
  ) async {
    final user = event.user;

    switch (state.status) {
      case AppStatus.authenticated:
      case AppStatus.unauthenticated:
      case AppStatus.loading:
        // User authentication state changed
        if (user.isAnonymous) {
          return emit(const AppState.unauthenticated());
        } else {
          // First emit authenticated state without changing loading state
          return emit(AppState.authenticated(user));
        }
    }
  }

  Future<void> _logoutRequested(
    AppLogoutRequested event,
    Emitter<AppState> emit,
  ) async {
    emit(state.copyWith(isFirstTime: false));

    // Clear the data loaded flag
    try {
      await AuthService.instance.clearDataLoadedFlag();
    } catch (e) {
      debugPrint('Failed to clear data loaded flag: $e');
    }

    // Clear local data before logout
    try {
      await DataClearingService.instance.clearAllLocalData();
      debugPrint('Successfully cleared local user data on logout');
    } catch (e) {
      debugPrint('Error clearing local user data: $e');
    }

    // Reset the data loading trigger flag
    isDataLoadingTriggered = false;

    // Then proceed with logout
    unawaited(_userRepository.logOut());
  }

  FutureOr<void> _appUpdateAccountRequested(
    AppUpdateAccountRequested event,
    Emitter<AppState> emit,
  ) async {
    try {
      await _userRepository.updateProfile(username: event.username);
    } catch (error, stackTrace) {
      addError(error, stackTrace);
    }
  }

  FutureOr<void> _appDeleteAccountRequested(
    AppDeleteAccountRequested event,
    Emitter<AppState> emit,
  ) async {
    try {
      await _userRepository.deleteAccount();
    } catch (error, stackTrace) {
      await _userRepository.logOut();
      addError(error, stackTrace);
    }
  }

  FutureOr<void> _appEmailUpdateRequest(
    AppEmailUpdateRequest event,
    Emitter<AppState> emit,
  ) async {
    try {
      await _userRepository.updateEmail(
        email: event.email!,
        password: event.password!,
      );
    } catch (error, stackTrace) {
      addError(error, stackTrace);
    }
  }

  /// Handle AppSetFirstTime event
  FutureOr<void> _appSetFirstTime(
    AppSetFirstTime event,
    Emitter<AppState> emit,
  ) {
    emit(state.copyWith(isFirstTime: event.isFirstTime));
  }

  /// Handle AppDataLoading event
  FutureOr<void> _appDataLoading(
    AppDataLoading event,
    Emitter<AppState> emit,
  ) {
    emit(state.copyWith(isDataLoading: true));
  }

  /// Handle AppDataLoaded event
  FutureOr<void> _appDataLoaded(
    AppDataLoaded event,
    Emitter<AppState> emit,
  ) {
    emit(state.copyWith(isDataLoading: false, hasData: event.hasData));
  }

  /// Handle AppDataLoadingError event
  FutureOr<void> _appDataLoadingError(
    AppDataLoadingError event,
    Emitter<AppState> emit,
  ) {
    emit(state.copyWith(
      isDataLoading: false,
      errorMessage: event.errorMessage,
    ));
  }

  @override
  Future<void> close() {
    _userSubscription?.cancel();
    return super.close();
  }
}
