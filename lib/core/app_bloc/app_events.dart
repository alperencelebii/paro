part of 'app_bloc.dart';

abstract class AppEvent {
  const AppEvent();
}

class AppUserChanged extends AppEvent {
  const AppUserChanged(this.user);

  final User user;
}

class AppLogoutRequested extends AppEvent {
  const AppLogoutRequested();
}

class AppUpdateAccountRequested extends AppEvent {
  const AppUpdateAccountRequested({required this.username});
  final String username;
}

class AppDeleteAccountRequested extends AppEvent {
  const AppDeleteAccountRequested();
}

class AppEmailUpdateRequest extends AppEvent {
  final String? email;
  final String? password;

  const AppEmailUpdateRequest({
    this.email,
    this.password,
  });
}

class AppSetFirstTime extends AppEvent {
  const AppSetFirstTime({required this.isFirstTime});

  final bool isFirstTime;
}

/// Event to indicate data loading is starting
class AppDataLoading extends AppEvent {
  const AppDataLoading();
}

/// Event to indicate data has been loaded
class AppDataLoaded extends AppEvent {
  const AppDataLoaded({required this.hasData});

  final bool hasData;
}

/// Event to indicate data loading error
class AppDataLoadingError extends AppEvent {
  const AppDataLoadingError(this.errorMessage);

  final String errorMessage;
}
