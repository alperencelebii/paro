import 'package:flutter_bloc/flutter_bloc.dart';

part 'navigation_state.dart';

/// Navigation tabs enum
enum NavigationTab {
  home,
  dashboard,
  analytics,
  profile,
}

/// Cubit to manage navigation state for the bottom navigation bar
class NavigationCubit extends Cubit<NavigationState> {
  NavigationCubit()
      : super(const NavigationState(currentTab: NavigationTab.home));

  /// Change the current tab
  void changeTab(NavigationTab tab) {
    emit(state.copyWith(currentTab: tab));
  }
}
