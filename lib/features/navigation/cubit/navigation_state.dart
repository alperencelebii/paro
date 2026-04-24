part of 'navigation_cubit.dart';

/// State for the navigation cubit
class NavigationState {
  final NavigationTab currentTab;

  const NavigationState({required this.currentTab});

  /// Create a copy with updated parameters
  NavigationState copyWith({
    NavigationTab? currentTab,
  }) {
    return NavigationState(
      currentTab: currentTab ?? this.currentTab,
    );
  }
}
