import 'dart:async';
import 'dart:developer';

import 'package:finance_track/core/app_bloc/app_bloc.dart';
import 'package:finance_track/core/models/currency_model.dart';
import 'package:finance_track/data/repositories/expense_repository.dart';
import 'package:finance_track/data/repositories/income_repository.dart';
import 'package:finance_track/features/auth/view/auth_page.dart';
import 'package:finance_track/features/dashboard/bloc/category_analysis_bloc.dart';
import 'package:finance_track/features/categories/screens/all_categories_screen.dart';
import 'package:finance_track/features/dashboard/screens/dashboard_screen.dart';
import 'package:finance_track/features/dashboard/screens/date_wise_expense_screen.dart';
import 'package:finance_track/features/categories/screens/category_detail_screen.dart';
import 'package:finance_track/features/expense_list/screens/expense_list_screen.dart';
import 'package:finance_track/features/home/screens/home_wrapper.dart';
import 'package:finance_track/features/income_list/screens/income_list_screen.dart';
import 'package:finance_track/features/landing/views/landing_screen.dart';
import 'package:finance_track/features/monthly_summary/blocs/monthly_summary_cubit.dart';
import 'package:finance_track/features/monthly_summary/screens/monthly_summary_screen.dart';
import 'package:finance_track/features/navigation/cubit/navigation_cubit.dart';
import 'package:finance_track/features/profile/faq_screen/view/faq_screen.dart';
import 'package:finance_track/features/profile/profile_edit/view/profile_edit_screen.dart';
import 'package:finance_track/features/profile/screens/profile_screen.dart';
import 'package:finance_track/features/splash/screens/splash_screen.dart';
import 'package:finance_track/features/splash/screens/update_required_screen.dart';
import 'package:finance_track/features/subscription/cubits/subscription_cubit/subscription_cubit.dart';
import 'package:finance_track/features/subscription/screens/purchases_page.dart'
    show PurchasesPage;
import 'package:finance_track/features/subscription/screens/subscription_management_screen.dart';
// Now using Tesseract OCR (supports 16KB page sizes)
import 'package:finance_track/features/invoice_scanner/ui/scanner_wrapper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'scaffold_with_bottom_nav.dart';
import 'auth_route_listener.dart';
import 'package:finance_track/features/budget/screens/budget_list_screen.dart';
import 'package:finance_track/features/budget/screens/budget_detail_screen.dart';
import 'package:finance_track/core/extensions/currency_context_extension.dart';

import '../../data/repositories/objectbox_expense_repository.dart';
import '../../data/repositories/objectbox_income_repository.dart';
import '../../data/repositories/firebase_expense_repository.dart';
import '../../data/repositories/firebase_income_repository.dart';
import '../../data/objectbox.dart';
import 'package:finance_track/features/profile/profile_security/view/privacy_policy_screen.dart';
import 'package:finance_track/features/profile/profile_security/view/privacy_security_screen.dart';
import 'package:finance_track/features/profile/help_support/view/help_support_screen.dart';
import 'package:finance_track/features/profile/send_message/screens/send_message_screen.dart';
import 'package:finance_track/features/profile/about/screens/about_screen.dart';
import 'package:finance_track/features/profile/about/bloc/about_state.dart';
import '../../features/profile/about/screens/feature_detail_screen.dart';
import 'package:finance_track/features/profile/export_data/screens/export_data_screen.dart';
import 'package:finance_track/data/models/budget_model.dart';
import 'package:finance_track/features/profile/categories/manage_categories_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:finance_track/features/auth/verify_email/view/verify_email_page.dart';

/// Custom page transition that slides from right to left
class SlideRightToLeftTransitionPage<T> extends CustomTransitionPage<T> {
  SlideRightToLeftTransitionPage({
    required super.child,
    required GoRouterState state,
    Curve curve = Curves.easeInOut,
    Duration duration = const Duration(milliseconds: 300),
  }) : super(
          key: state.pageKey,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );
            final offsetAnimation = animation.drive(tween);

            return SlideTransition(
              position: offsetAnimation,
              child: child,
            );
          },
          transitionDuration: duration,
        );
}

/// Custom dialog page transition for showing dialogs via router
class DialogTransitionPage<T> extends CustomTransitionPage<T> {
  DialogTransitionPage({
    required super.child,
    required GoRouterState state,
    super.barrierDismissible = true,
    Color? barrierColor,
    Curve curve = Curves.easeOut,
    Duration duration = const Duration(milliseconds: 200),
  }) : super(
          key: state.pageKey,
          fullscreenDialog: false,
          barrierColor: barrierColor ?? Colors.black54,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: curve,
            );

            return FadeTransition(
              opacity: curvedAnimation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.8, end: 1.0)
                    .animate(curvedAnimation),
                child: child,
              ),
            );
          },
          transitionDuration: duration,
          reverseTransitionDuration: duration,
        );
}

/// Route names used for navigation
class AppRoutes {
  static const String splash = 'splash';
  static const String update = 'update-required';
  static const String home = 'home';
  static const String dashboard = 'dashboard';
  static const String analytics = 'analytics';
  static const String profile = 'profile';
  static const String addExpense = 'add-expense';
  static const String addIncome = 'add-income';
  static const String incomeList = 'income-list';
  static const String expenseList = 'expense-list';
  static const String monthlySummary = 'monthly-summary';
  static const String categoryDetail = 'category-detail';
  static const String allCategories = 'all-categories';
  static const String auth = 'auth';
  static const String landing = 'landing';
  static const String budgetSettings = 'budget-settings';
  // static const String addBudget = 'add-budget';
  static const String budgetDetail = 'budget-detail';
  static const String privacySecurity = 'privacy-security';
  static const String privacyPolicy = 'privacy-policy';
  static const String helpSupport = 'help-support';
  static const String sendMessage = 'send-message';
  static const String about = 'about';
  static const String featureDetail = 'feature-detail';
  static const String exportData = 'export-data';
  static const String faqScreen = 'faq-screen';
  static const String profileEdit = 'profile-edit';
  static const String manageCategories = 'manage-categories';
  static const String verifyEmail = 'verify-email';
  static const String purchasesPage = 'purchasesPage';
  static const String dateWiseExpense = 'date-wise-expense';
  static const String subscriptionManagement = 'subscription-management';
  static const String invoiceScanner = 'invoice-scanner';
  static const String invoiceScannerCrop = 'invoice-scanner-crop';
  static const String invoiceScannerPreview = 'invoice-scanner-preview';
}

/// Path names used for routing
class AppPaths {
  static const String splash = '/splash';
  static const String update = '/update-required';
  static const String faqScreen = '/faq-screen';
  static const String home = '/';
  static const String dashboard = '/dashboard';
  static const String analytics = '/analytics';
  static const String profile = '/profile';
  static const String profileEdit = '/profile-edit';
  static const String addExpense = '/add-expense';
  static const String addIncome = '/add-income';
  static const String incomeList = '/income-list';
  static const String expenseList = '/expense-list';
  static const String monthlySummary = '/monthly-summary';
  static const String categoryDetail = '/category-detail';
  static const String allCategories = '/all-categories';
  static const String auth = '/auth';
  static const String landing = '/landing';
  static const String budgetSettings = '/budget-settings';
  // static const String addBudget = '/add-budget';
  static const String privacySecurity = '/privacy-security';
  static const String privacyPolicy = '/privacy-policy';
  static const String helpSupport = '/help-support';
  static const String sendMessage = '/send-message';
  static const String about = '/about';
  static const String featureDetail = '/feature-detail';
  static const String exportData = '/export-data';
  static const String manageCategories = '/manage-categories';
  static const String verifyEmail = '/verify-email';
  static const String purchasesPage = '/purchasesPage';
  static const String dateWiseExpense = '/date-wise-expense';
  static const String budgetDetail = '/budget-detail';
  static const String subscriptionManagement = '/subscription-management';
  static const String invoiceScanner = '/invoice-scanner';
  static const String invoiceScannerCrop = '/invoice-scanner/crop';
  static const String invoiceScannerPreview = '/invoice-scanner/preview';

  /// Get path for a tab
  static String getPathForTab(NavigationTab tab) {
    switch (tab) {
      case NavigationTab.home:
        return home;
      case NavigationTab.dashboard:
        return dashboard;
      case NavigationTab.analytics:
        return analytics;
      case NavigationTab.profile:
        return profile;
    }
  }
}

/// Router configuration for the application
class AppRouter {
  final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  late final NavigationCubit _navigationCubit;

  /// Initialize with navigation cubit
  AppRouter(this._navigationCubit);

  /// The GoRouter configuration
  GoRouter router(AppBloc appBloc) => GoRouter(
        navigatorKey: _rootNavigatorKey,
        initialLocation: AppPaths.splash,
        debugLogDiagnostics: false,
        observers: [GoRouterObserver(), AuthRouteListener()],
        routes: [
          // Splash screen route
          GoRoute(
            path: AppPaths.splash,
            name: AppRoutes.splash,
            builder: (context, state) => const SplashScreen(),
          ),
          // Update required route (blocks app until updated)
          GoRoute(
            path: AppPaths.update,
            name: AppRoutes.update,
            builder: (context, state) => const UpdateRequiredScreen(),
          ),
          // Landing page route
          GoRoute(
            path: AppPaths.landing,
            name: AppRoutes.landing,
            builder: (context, state) => const LandingScreen(),
          ),
          // StatefulShellRoute for bottom navigation with state persistence
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) {
              // The StatefulNavigationShell maintains state across tab navigations
              return ScaffoldWithBottomNav(
                navigationCubit: _navigationCubit,
                navigationShell: navigationShell,
              );
            },
            branches: [
              // Home tab branch
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppPaths.home,
                    name: AppRoutes.home,
                    pageBuilder: (context, state) => NoTransitionPage(
                      key: state.pageKey,
                      child: const HomeWrapper(),
                    ),
                  ),
                ],
              ),
              // Dashboard tab branch
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppPaths.dashboard,
                    name: AppRoutes.dashboard,
                    pageBuilder: (context, state) => NoTransitionPage(
                      key: state.pageKey,
                      child: const DashboardScreen(),
                    ),
                  ),
                ],
              ),
              // Analytics tab branch (show All Categories instead of legacy Analytics)
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppPaths.analytics,
                    name: AppRoutes.analytics,
                    pageBuilder: (context, state) => NoTransitionPage(
                      key: state.pageKey,
                      child: BlocProvider<CategoryAnalysisBloc>(
                        create: (context) => CategoryAnalysisBloc(
                          expenseRepository: context.read<ExpenseRepository>(),
                          incomeRepository: context.read<IncomeRepository>(),
                        )..add(const LoadCategoryAnalysis()),
                        child: AllCategoriesScreen(
                          currency: context.selectedCurrency,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Profile tab branch
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppPaths.profile,
                    name: AppRoutes.profile,
                    pageBuilder: (context, state) => NoTransitionPage(
                      key: state.pageKey,
                      child: const ProfileScreen(),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: AppPaths.auth,
            name: AppRoutes.auth,
            builder: (context, state) => const AuthPage(),
          ),
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: AppPaths.verifyEmail,
            name: AppRoutes.verifyEmail,
            pageBuilder: (context, state) => SlideRightToLeftTransitionPage(
              state: state,
              child: const VerifyEmailPage(),
            ),
          ),
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: AppPaths.profileEdit,
            name: AppRoutes.profileEdit,
            pageBuilder: (context, state) => SlideRightToLeftTransitionPage(
              state: state,
              child: const ProfileEditScreen(),
            ),
          ),
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: AppPaths.manageCategories,
            name: AppRoutes.manageCategories,
            pageBuilder: (context, state) => SlideRightToLeftTransitionPage(
              state: state,
              child: const ManageCategoriesScreen(),
            ),
          ),

          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: AppPaths.faqScreen,
            name: AppRoutes.faqScreen,
            pageBuilder: (context, state) => SlideRightToLeftTransitionPage(
              state: state,
              child: const FaqScreen(),
            ),
          ),
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: AppPaths.purchasesPage,
            name: AppRoutes.purchasesPage,
            pageBuilder: (context, state) => SlideRightToLeftTransitionPage(
              state: state,
              child: const PurchasesPage(),
            ),
          ),

          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: AppPaths.incomeList,
            name: AppRoutes.incomeList,
            pageBuilder: (context, state) => SlideRightToLeftTransitionPage(
              state: state,
              child: const IncomeListScreen(),
            ),
          ),
          // Expense List route
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: AppPaths.expenseList,
            name: AppRoutes.expenseList,
            pageBuilder: (context, state) => SlideRightToLeftTransitionPage(
              state: state,
              child: const ExpenseListScreen(),
            ),
          ),
          // Monthly Summary route
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: AppPaths.monthlySummary,
            name: AppRoutes.monthlySummary,
            pageBuilder: (context, state) => SlideRightToLeftTransitionPage(
              state: state,
              child: MultiRepositoryProvider(
                providers: [
                  RepositoryProvider<ExpenseRepository>(
                    create: (context) => FirebaseExpenseRepository(),
                  ),
                  RepositoryProvider<IncomeRepository>(
                    create: (context) => FirebaseIncomeRepository(),
                  ),
                ],
                child: BlocProvider<MonthlySummaryCubit>(
                  create: (context) => MonthlySummaryCubit(
                    expenseRepository: context.read<ExpenseRepository>(),
                    incomeRepository: context.read<IncomeRepository>(),
                  )..loadMonthlySummary(context),
                  child: const MonthlySummaryScreen(),
                ),
              ),
            ),
          ),
          // Category Detail route
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: AppPaths.categoryDetail,
            name: AppRoutes.categoryDetail,
            pageBuilder: (context, state) {
              // The detail screen is passed as extra parameter
              final detailScreen = state.extra as Map<String, dynamic>;
              final isExpense = detailScreen['isExpense'] as bool;
              final category = detailScreen['category'];
              final currency = detailScreen['currency'] as Currency;

              // Create dateRange based on time frame (default to 30 days if not provided)
              final timeFrame = detailScreen['timeFrame'] as int? ?? 30;
              final dateRange = detailScreen['dateRange'] as DateTimeRange? ??
                  DateTimeRange(
                    start: DateTime.now().subtract(Duration(days: timeFrame)),
                    end: DateTime.now(),
                  );

              return SlideRightToLeftTransitionPage(
                state: state,
                child: BlocProvider<CategoryAnalysisBloc>(
                  create: (context) => CategoryAnalysisBloc(
                    expenseRepository: context.read<ExpenseRepository>(),
                    incomeRepository: context.read<IncomeRepository>(),
                  )..add(
                      LoadCategoryDetail(
                        category: category,
                        isExpense: isExpense,
                        timeFrame: timeFrame,
                        dateRange: dateRange,
                      ),
                    ),
                  child: CategoryDetailScreen(
                    category: category,
                    isExpense: isExpense,
                    currency: currency,
                    dateRange: dateRange,
                  ),
                ),
              );
            },
          ),
          // All Categories route
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: AppPaths.allCategories,
            name: AppRoutes.allCategories,
            pageBuilder: (context, state) {
              final extraData = state.extra as Map<String, dynamic>;
              final categoryAnalysisBloc =
                  extraData['categoryAnalysisBloc'] as CategoryAnalysisBloc;
              final currency = extraData['currency'] as Currency;

              return SlideRightToLeftTransitionPage(
                state: state,
                child: BlocProvider<CategoryAnalysisBloc>.value(
                  value: categoryAnalysisBloc,
                  child: AllCategoriesScreen(currency: currency),
                ),
              );
            },
          ),
          // Budget Settings route
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: AppPaths.budgetSettings,
            name: AppRoutes.budgetSettings,
            pageBuilder: (context, state) => SlideRightToLeftTransitionPage(
              state: state,
              child: const BudgetListScreen(),
            ),
          ),
          // Add Budget route (dialog)
          // GoRoute(
          //   parentNavigatorKey: _rootNavigatorKey,
          //   path: AppPaths.addBudget,
          //   name: AppRoutes.addBudget,
          //   pageBuilder: (context, state) {
          //     final Budget? budget = state.extra != null
          //         ? (state.extra as Map<String, dynamic>)['budget'] as Budget?
          //         : null;

          //     return DialogTransitionPage(
          //       state: state,
          //       child: BudgetFormScreen(budget: budget),
          //     );
          //   },
          // ),

          // Budget Detail route
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: AppPaths.budgetDetail,
            name: AppRoutes.budgetDetail,
            pageBuilder: (context, state) {
              // Robustly accept either a Budget or a Map payload in state.extra
              final extra = state.extra;
              late final Budget budget;
              if (extra is Budget) {
                budget = extra;
              } else if (extra is Map<String, dynamic>) {
                final raw = extra['budget'];
                if (raw is Budget) {
                  budget = raw;
                } else if (raw is Map<String, dynamic>) {
                  budget = Budget.fromJson(raw);
                } else {
                  throw ArgumentError('Invalid budget payload in route extra');
                }
              } else {
                throw ArgumentError('Missing budget in route extra');
              }
              return SlideRightToLeftTransitionPage(
                state: state,
                child: MultiRepositoryProvider(
                  providers: [
                    RepositoryProvider<ExpenseRepository>(
                      create: (context) =>
                          ObjectBoxExpenseRepository(ObjectBox.instance),
                    ),
                    RepositoryProvider<IncomeRepository>(
                      create: (context) =>
                          ObjectBoxIncomeRepository(ObjectBox.instance),
                    ),
                  ],
                  child: BudgetDetailScreen(budget: budget),
                ),
              );
            },
          ),
          // Privacy and Security route
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: AppPaths.privacySecurity,
            name: AppRoutes.privacySecurity,
            pageBuilder: (context, state) => SlideRightToLeftTransitionPage(
              state: state,
              child: const PrivacySecurityScreen(),
            ),
          ),
          // Privacy Policy route
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: AppPaths.privacyPolicy,
            name: AppRoutes.privacyPolicy,
            pageBuilder: (context, state) => SlideRightToLeftTransitionPage(
              state: state,
              child: const PrivacyPolicyScreen(),
            ),
          ),
          // Help & Support route
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: AppPaths.helpSupport,
            name: AppRoutes.helpSupport,
            pageBuilder: (context, state) => SlideRightToLeftTransitionPage(
              state: state,
              child: const HelpSupportScreen(),
            ),
          ),
          // Send Message route
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: AppPaths.sendMessage,
            name: AppRoutes.sendMessage,
            pageBuilder: (context, state) => SlideRightToLeftTransitionPage(
              state: state,
              child: const SendMessageScreen(),
            ),
          ),
          // About screen route
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: AppPaths.about,
            name: AppRoutes.about,
            pageBuilder: (context, state) => SlideRightToLeftTransitionPage(
              state: state,
              child: const AboutScreen(),
            ),
          ),
          // Feature Detail route
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: AppPaths.featureDetail,
            name: AppRoutes.featureDetail,
            pageBuilder: (context, state) {
              final feature = state.extra as FeatureInfo;

              return SlideRightToLeftTransitionPage(
                state: state,
                child: FeatureDetailScreen(feature: feature),
              );
            },
          ),
          // Export Data route
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: AppPaths.exportData,
            name: AppRoutes.exportData,
            pageBuilder: (context, state) => SlideRightToLeftTransitionPage(
              state: state,
              child: const ExportDataScreen(),
            ),
          ),
          // Date-wise Expense route
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: AppPaths.dateWiseExpense,
            name: AppRoutes.dateWiseExpense,
            pageBuilder: (context, state) => SlideRightToLeftTransitionPage(
              state: state,
              child: const DateWiseExpenseScreen(),
            ),
          ),
          // Subscription Management route
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: AppPaths.subscriptionManagement,
            name: AppRoutes.subscriptionManagement,
            pageBuilder: (context, state) => SlideRightToLeftTransitionPage(
              state: state,
              child: const SubscriptionManagementScreen(),
            ),
          ),
          // Invoice Scanner route - now using Tesseract OCR (supports 16KB)
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: AppPaths.invoiceScanner,
            name: AppRoutes.invoiceScanner,
            pageBuilder: (context, state) => SlideRightToLeftTransitionPage(
              state: state,
              child: const ScannerWrapper(),
            ),
          ),
        ],
        redirect: (BuildContext context, GoRouterState state) {
          final appState = appBloc.state;
          final authenticated = appState.status == AppStatus.authenticated;
          final authenticating = state.matchedLocation == AppPaths.auth;
          final splashing = state.matchedLocation == AppPaths.splash;
          final landing = state.matchedLocation == AppPaths.landing;
          final verifying = state.matchedLocation == AppPaths.verifyEmail;

          // Don't redirect if we're on the splash screen
          if (splashing) {
            return null;
          }

          // If user is not authenticated and not already on landing page
          if (!authenticated && !landing) {
            // Always direct to landing page for unauthenticated users
            return AppPaths.auth;
          }

          // If user is authenticated but not email verified, force verify page
          if (authenticated) {
            final user = FirebaseAuth.instance.currentUser;
            final emailVerified = user?.emailVerified ?? false;
            if (!emailVerified && !verifying) {
              return AppPaths.verifyEmail;
            }
            if (emailVerified && (landing || authenticating || verifying)) {
              return AppPaths.home;
            }

            // Force refresh subscription status on login to ensure latest status from RevenueCat
            // Note: This is non-blocking - runs in background
            try {
              log('[AppRouter] Triggering subscription status check (non-blocking)...');
              final SubscriptionCubit subscriptionCubit =
                  context.read<SubscriptionCubit>();
              // This is non-blocking - runs in background, doesn't block navigation
              unawaited(subscriptionCubit.checkProStatus(forceRefresh: true));
              log('[AppRouter] ✓ Subscription status check triggered (running in background)');
            } catch (e, stackTrace) {
              log(
                '[AppRouter] ✗ Error triggering subscription status check: $e',
                error: e,
                stackTrace: stackTrace,
              );
              // Don't block navigation on error
            }
          }

          // Otherwise, don't redirect
          return null;
        },
        refreshListenable: GoRouterAppBlocRefreshStream(appBloc.stream),
      );
}

/// {@template go_router_refresh_stream}
/// A [ChangeNotifier] that notifies its listeners whena [Stream] emits a value/
/// This is used to rebuild the UI when the [AppBloc] emits a new State
/// {@endtemplate}

class GoRouterAppBlocRefreshStream extends ChangeNotifier {
  /// {@macro go_router_refresh_stream}
  GoRouterAppBlocRefreshStream(Stream<AppState> stream) {
    _subscription = stream.asBroadcastStream().listen((state) {
      notifyListeners();
    });
  }
  late final StreamSubscription<dynamic> _subscription;
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Observer for GoRouter
class GoRouterObserver extends NavigatorObserver {
  // Set this to false to disable debug prints that may cause lag
  static const bool enableDebugPrints = false;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (kDebugMode && enableDebugPrints) {}
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (kDebugMode && enableDebugPrints) {}
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (kDebugMode && enableDebugPrints) {}
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (kDebugMode && enableDebugPrints) {}
  }
}
