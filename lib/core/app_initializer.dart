import 'package:finance_track/core/constants/api_constant.dart';
import 'package:finance_track/core/services/auth_service.dart';
import 'package:finance_track/data/objectbox.dart';

import 'package:finance_track/data/repositories/composite_budget_repository.dart';
import 'package:finance_track/features/subscription/services/subscription_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_authentication_client/firebase_authentication_client.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:user_repository/user_repository.dart';
import 'package:token_storage/token_storage.dart';

import '../app.dart';
import '../data/repositories/expense_repository.dart';
import '../data/repositories/income_repository.dart';
import '../data/repositories/category_repository.dart';
import 'bootstrap.dart';

/// Custom BlocObserver to debug Bloc events and transitions
class AppBlocObserver extends BlocObserver {
  // Set this to true to enable debug prints (warning: may cause lag)
  static const bool enableDebugPrints = false;

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    // Disabled to improve performance
    if (enableDebugPrints) {
      debugPrint('${bloc.runtimeType} received event: $event');
    }
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    // Disabled to improve performance
    if (enableDebugPrints) {
      debugPrint('${bloc.runtimeType} transition: ${transition.event} - '
          'currentState: ${transition.currentState.runtimeType}, '
          'nextState: ${transition.nextState.runtimeType}');
    }
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    // Keep error logging enabled as it's important for debugging issues
    debugPrint('${bloc.runtimeType} error: $error');
    super.onError(bloc, error, stackTrace);
  }
}

/// Initialize the app with all required setup
Future<void> initializeApp() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  await SubscriptionService.configureRevenueCat( ApiConstants.revenueCatApiKey??'');
  // Initialize Firebase
  // Firebase is already initialized in main.dart

  // Facebook Auth is already initialized in main.dart

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set up BlocObserver for debugging
  Bloc.observer = AppBlocObserver();

  // Initialize ObjectBox singleton
  await ObjectBox.initialize();

  // Initialize repository and handle errors
  final repositoryResult = await initializeRepositories();

  // Initialize token storage
  final tokenStorage = InMemoryTokenStorage();

// Update Google Sign In
  final googleSignIn = GoogleSignIn.instance;
  await googleSignIn.initialize(
// How to get and  update the clientId and serverClientId
// Check this Document setup-/google_sign_setup.md

      clientId:
         ApiConstants.googleClientId ?? '' );

  // Initialize authentication client
  final authenticationClient = FirebaseAuthenticationClient(
    tokenStorage: tokenStorage,
    googleSignIn: googleSignIn,
  );

  // Initialize user repository
  final userRepository = UserRepository(
    authenticationClient: authenticationClient,
  );

  // Initialize auth service
  AuthService.instance.initialize();

  // Create and run the app
  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ExpenseRepository>(
          create: (context) => repositoryResult.expenseRepository,
        ),
        RepositoryProvider<IncomeRepository>(
          create: (context) => repositoryResult.incomeRepository,
        ),
        if (repositoryResult.categoryRepository != null)
          RepositoryProvider<CategoryRepository>(
            create: (context) => repositoryResult.categoryRepository!,
          ),
        RepositoryProvider<CompositeBudgetRepository>(
          create: (context) => repositoryResult.budgetRepository,
        ),
        RepositoryProvider<UserRepository>(
          create: (context) => userRepository,
        ),
      ],
      child: const ExpenseApp(),
    ),
  );
}


Future<void> loadEnv() async {
  try {
    await dotenv.load(fileName: '.env');
    debugPrint('✓ .env file loaded successfully');
  } catch (e) {
    // .env file doesn't exist or couldn't be loaded
    // This is okay - ApiConstants will handle missing values gracefully
    final errorMessage = e.toString();
    if (errorMessage.contains('Unable to load asset') ||
        errorMessage.contains('does not exist') ||
        errorMessage.contains('FlutterError')) {
      debugPrint('ℹ .env file not found. Using default values.');
      debugPrint(
          '   To configure API keys, create a .env file in the project root and add it to pubspec.yaml assets.');
    } else {
      debugPrint('Warning: Could not load .env file: $e');
    }
  }
}