import 'package:finance_track/core/app_bloc/app_bloc.dart';
import 'package:finance_track/data/repositories/composite_budget_repository.dart';
import 'package:finance_track/features/budget/bloc/budget_bloc/budget_bloc.dart';
import 'package:finance_track/features/subscription/cubits/purchases_cubit/purchases_cubit.dart';
import 'package:finance_track/features/subscription/cubits/subscription_cubit/subscription_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:user_repository/user_repository.dart';

import 'core/theme/theme.dart';
import 'features/profile/currency/bloc/currency/currency_bloc.dart';
import 'features/profile/currency/bloc/currency/currency_event.dart';
import 'core/connectivity/connectivity_cubit.dart';
import 'core/providers/animation_provider.dart';
import 'core/router/app_router.dart';
import 'core/router/navigation_manager.dart';
import 'core/services/currency_service.dart';
import 'core/widgets/connectivity_banner.dart';
import 'data/repositories/expense_repository.dart';
import 'data/repositories/income_repository.dart';
import 'features/expense_list/add_expense_bloc/add_expense_bloc.dart';
import 'features/income_list/add_income_bloc/add_income_bloc.dart';
import 'features/analytics/cubit/analytics_cubit.dart';
import 'features/dashboard/cubit/dashboard_cubit.dart';
import 'features/expense_list/bloc/expense_list_bloc.dart';
import 'features/expense_list/bloc/expense_list_event.dart';
import 'features/income_list/bloc/income_list_bloc.dart';
import 'features/income_list/bloc/income_list_event.dart';
import 'features/navigation/cubit/navigation_cubit.dart';
import 'features/analytics/bloc/transaction_analytics_bloc.dart';
import 'features/analytics/bloc/transaction_analytics_event.dart';
// Now using Tesseract OCR (free, open-source) - supports 16KB page sizes
import 'features/invoice_scanner/bloc/scanner_bloc.dart';
import 'features/invoice_scanner/services/ocr_service.dart';
import 'features/invoice_scanner/services/parser_service.dart';

/// The main application widget
class ExpenseApp extends StatelessWidget {
  final GlobalKey<NavigatorState>? navigatorKey;
  final bool databaseError;
  final String errorMessage;

  const ExpenseApp({
    super.key,
    this.navigatorKey,
    this.databaseError = false,
    this.errorMessage = '',
  });

  @override
  Widget build(BuildContext context) {
    // Repositories are provided in main.dart
    final expenseRepository = context.read<ExpenseRepository>();
    final incomeRepository = context.read<IncomeRepository>();
    final budgetRepository = context.read<CompositeBudgetRepository>();
    final userRepository = context.read<UserRepository>();

    // Create app bloc with user repository
    final appBloc =
        AppBloc(user: User.anonymous, userRepository: userRepository);

    // Create navigation cubit
    final navigationCubit = NavigationCubit();

    // Create connectivity cubit
    final connectivityCubit = ConnectivityCubit();

    // Create app router with navigation cubit
    final appRouter = AppRouter(navigationCubit);

    // Create navigation manager
    final navigationManager = NavigationManager(
      navigationCubit: navigationCubit,
      router: appRouter.router(appBloc),
    );
    // Create currency service
    final currencyService = CurrencyService();

    // Create BudgetBloc
    final budgetBloc = BudgetBloc(budgetRepository: budgetRepository);

    // Create animation provider
    final animationProvider = AnimationProvider();

    return MultiProvider(
      providers: [
        Provider<NavigationManager>.value(value: navigationManager),
        ChangeNotifierProvider<AnimationProvider>.value(
            value: animationProvider),
        MultiBlocProvider(
          providers: [
            BlocProvider<AppBloc>.value(value: appBloc),
            BlocProvider<SubscriptionCubit>(
                create: (context) => SubscriptionCubit()),
            BlocProvider<PurchasesCubit>(create: (context) => PurchasesCubit()),
            BlocProvider<NavigationCubit>.value(value: navigationCubit),
            BlocProvider<ConnectivityCubit>.value(value: connectivityCubit),
            BlocProvider<ExpenseListBloc>(
              create: (context) {
                final bloc = ExpenseListBloc(expenseRepository);
                // Load expenses when the app starts
                bloc.add(const LoadExpenses());
                return bloc;
              },
            ),
            BlocProvider<IncomeListBloc>(
              create: (context) {
                final bloc = IncomeListBloc(incomeRepository);
                // Load incomes when the app starts
                bloc.add(const LoadIncomes());
                return bloc;
              },
            ),
            BlocProvider<BudgetBloc>.value(value: budgetBloc),
            BlocProvider<AddExpenseBloc>(
              create: (context) => AddExpenseBloc(expenseRepository),
            ),
            BlocProvider<AddIncomeBloc>(
              create: (context) => AddIncomeBloc(incomeRepository),
            ),
            BlocProvider<AnalyticsCubit>(
              create: (context) => AnalyticsCubit(
                expenseRepository: expenseRepository,
                incomeRepository: incomeRepository,
              ),
            ),
            BlocProvider<DashboardCubit>(
              create: (context) => DashboardCubit(
                expenseRepository: expenseRepository,
                incomeRepository: incomeRepository,
                budgetBloc: budgetBloc,
              ),
            ),
            BlocProvider<CurrencyBloc>(
              create: (context) {
                final bloc = CurrencyBloc(currencyService: currencyService);
                // Load currency when the app starts
                bloc.add(const LoadCurrency());
                return bloc;
              },
            ),
            BlocProvider<TransactionAnalyticsBloc>(
              create: (context) {
                final bloc = TransactionAnalyticsBloc(
                  expenseRepository: expenseRepository,
                  incomeRepository: incomeRepository,
                );
                // Load transactions when the app starts (no filters by default)
                bloc.add(const LoadTransactionAnalytics());
                return bloc;
              },
            ),
            // Invoice Scanner Bloc - now using Tesseract OCR (supports 16KB)
            BlocProvider<ScannerBloc>(
              create: (context) {
                final ocrService = OcrService();
                final parserService = ParserService();
                return ScannerBloc(
                  ocrService: ocrService,
                  parserService: parserService,
                  expenseRepository: expenseRepository,
                );
              },
            ),
          ],
          child: ScreenUtilInit(
              designSize: const Size(360, 800),
              minTextAdapt: true,
              splitScreenMode: true,
              builder: (context, child) {
                return MaterialApp.router(
                  title: 'Finance Track',
                  theme: lightThemeData(),
                  debugShowCheckedModeBanner: false,
                  darkTheme: darkThemeData(),
                  themeMode: ThemeMode.light,
                  routerConfig: appRouter.router(appBloc),
                  builder: (context, child) {
                    return ConnectivityBanner(
                      child: child ?? const SizedBox.shrink(),
                    );
                  },
                );
              }),
        ),
      ],
    );
  }
}
