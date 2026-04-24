import 'package:finance_track/features/navigation/cubit/navigation_cubit.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_router.dart';

/// A manager class for handling navigation throughout the app
class NavigationManager {
  final NavigationCubit _navigationCubit;
  final GoRouter _router;

  /// Constructor
  NavigationManager({
    required NavigationCubit navigationCubit,
    required GoRouter router,
  })  : _navigationCubit = navigationCubit,
        _router = router;

  /// Navigate to a specific tab
  void navigateToTab(NavigationTab tab) {
    final String path = AppPaths.getPathForTab(tab);
    _router.go(path);
    _navigationCubit.changeTab(tab);
  }

  /// Navigate to the home tab
  void navigateToHome() => navigateToTab(NavigationTab.home);

  /// Navigate to the dashboard tab
  void navigateToDashboard() => navigateToTab(NavigationTab.dashboard);

  /// Navigate to the analytics tab
  void navigateToAnalytics() => navigateToTab(NavigationTab.analytics);

  /// Navigate to the profile tab
  void navigateToProfile() => navigateToTab(NavigationTab.profile);

  /// Navigate to the add expense screen
  void navigateToAddExpense() => _router.goNamed(AppRoutes.addExpense);

  /// Navigate back
  void goBack() => _router.pop();

  /// Navigate to a named route
  void navigateToNamed(String routeName, {Map<String, String>? params}) {
    _router.goNamed(
      routeName,
      pathParameters: params ?? {},
    );
  }

  /// Create a global key for accessing the current BuildContext
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Get the current BuildContext from the navigator key
  static BuildContext? get currentContext => navigatorKey.currentContext;

  /// Get the current GoRouter from BuildContext
  static GoRouter of(BuildContext context) => GoRouter.of(context);

  /// Extension method for BuildContext to navigate using GoRouter
  static void go(BuildContext context, String path) => context.go(path);

  /// Extension method for BuildContext to push using GoRouter
  static void push(BuildContext context, String path) => context.push(path);

  /// Extension method for BuildContext to push replacement using GoRouter
  static void pushReplacement(BuildContext context, String path) =>
      context.pushReplacement(path);

  /// Extension method for BuildContext to go with named route using GoRouter
  static void goToNamed(BuildContext context, String name,
          {Map<String, String>? params}) =>
      context.goNamed(name, pathParameters: params ?? {});
}
