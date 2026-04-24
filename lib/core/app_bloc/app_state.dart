part of 'app_bloc.dart';

enum AppStatus { authenticated, unauthenticated, loading }

class AppState extends Equatable {
  const AppState({
    required this.status,
    required this.user,
    this.error,
    this.isFirstTime = false,
    this.isDataLoading = false,
    this.hasData = false,
    this.errorMessage,
  });
  const AppState.authenticated(User user)
      : this._(status: AppStatus.authenticated, user: user);
  const AppState.unauthenticated()
      : this._(status: AppStatus.unauthenticated, user: User.anonymous);
  const AppState.loading()
      : this._(status: AppStatus.loading, user: User.anonymous);

  const AppState._({
    required this.status,
    required this.user,
    this.error,
    this.isFirstTime = false,
    this.isDataLoading = false,
    this.hasData = false,
    this.errorMessage,
  });

  final AppStatus status;
  final String? error;
  final User user;
  final bool isFirstTime;
  final bool isDataLoading;
  final bool hasData;
  final String? errorMessage;

  @override
  List<Object?> get props => [
        status,
        error,
        user,
        isFirstTime,
        isDataLoading,
        hasData,
        errorMessage,
      ];

  AppState copyWith({
    AppStatus? status,
    String? error,
    User? user,
    bool? isFirstTime,
    bool? isDataLoading,
    bool? hasData,
    String? errorMessage,
  }) {
    return AppState(
      status: status ?? this.status,
      error: error ?? this.error,
      user: user ?? this.user,
      isFirstTime: isFirstTime ?? this.isFirstTime,
      isDataLoading: isDataLoading ?? this.isDataLoading,
      hasData: hasData ?? this.hasData,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
