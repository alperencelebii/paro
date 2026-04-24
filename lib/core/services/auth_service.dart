import 'dart:async';
import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_track/features/expense_list/bloc/expense_list_bloc.dart';
import 'package:finance_track/features/expense_list/bloc/expense_list_event.dart';
import 'package:finance_track/features/income_list/bloc/income_list_bloc.dart';
import 'package:finance_track/features/income_list/bloc/income_list_event.dart';
import 'package:finance_track/features/budget/bloc/budget_bloc/budget_bloc.dart';
import 'package:finance_track/features/subscription/cubits/subscription_cubit/subscription_cubit.dart';
import 'package:finance_track/features/subscription/services/subscription_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'data_fetching_service.dart';

/// Service to handle authentication and related data operations
class AuthService {
  static final AuthService _instance = AuthService._internal();

  /// Singleton instance
  static AuthService get instance => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<User?>? _authStateSubscription;

  bool _isInitialized = false;
  bool _hasSeenInitialAuthState = false;
  
  // Track RevenueCat identification status per user
  final Map<String, Completer<void>> _revenueCatIdentificationCompleters = {};
  final Set<String> _identifiedUsers = {};

  /// Private constructor
  AuthService._internal();

  /// Initialize the service
  void initialize() {
    if (_isInitialized) return;

    // Listen for auth state changes
    _authStateSubscription =
        _auth.authStateChanges().listen(_onAuthStateChanged);

    // Clear any stale Google sign-in state on app startup
    _clearCachedGoogleCredentials();

    // If user is already logged in when app starts, identify them in RevenueCat
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      dev.log('User already logged in on app startup: ${currentUser.uid}');
      // Identify user in RevenueCat to restore purchases
      unawaited(_identifyUserInRevenueCat(currentUser.uid));
    }

    _isInitialized = true;
    dev.log('AuthService initialized');
  }

  /// Handle auth state changes
  void _onAuthStateChanged(User? user) {
    // Track if we've seen the initial auth state
    // On app startup, Firebase emits null if no user is logged in
    // We should only log out from RevenueCat if this is an actual logout, not initial state
    final isInitialState = !_hasSeenInitialAuthState;
    _hasSeenInitialAuthState = true;

    if (user != null) {
      dev.log('User signed in: ${user.uid}');
      // CRITICAL: Identify user in RevenueCat to restore their purchases
      // This must be done when user logs in so RevenueCat knows which purchases to restore
      // Start identification immediately (don't await to avoid blocking)
      unawaited(_identifyUserInRevenueCat(user.uid));
      // Ensure the user's root document exists and is populated safely
      // Fire-and-forget to avoid blocking UI
      unawaited(_ensureUserDocument(user));
    } else {
      // Only log out from RevenueCat if this is not the initial state
      // (i.e., user actually signed out, not just app startup with no user)
      if (isInitialState) {
        dev.log('No user logged in on app startup (initial state)');
        // Don't try to log out anonymous user on startup - this would cause an error
      } else {
        dev.log('User signed out');
        // Clear identification cache
        _identifiedUsers.clear();
        _revenueCatIdentificationCompleters.clear();
        // Log out from RevenueCat when user signs out
        unawaited(SubscriptionService.logOutUser());
      }
    }
  }

  /// Identify user in RevenueCat with their Firebase UID
  /// This is essential for RevenueCat to restore purchases
  Future<void> _identifyUserInRevenueCat(String userId) async {
    // If already identified, return immediately
    if (_identifiedUsers.contains(userId)) {
      dev.log('User already identified in RevenueCat: $userId');
      return;
    }

    // If identification is in progress, wait for it
    if (_revenueCatIdentificationCompleters.containsKey(userId)) {
      dev.log('RevenueCat identification already in progress for: $userId');
      await _revenueCatIdentificationCompleters[userId]!.future;
      return;
    }

    // Start new identification
    final completer = Completer<void>();
    _revenueCatIdentificationCompleters[userId] = completer;

    try {
      dev.log('=== IDENTIFYING USER IN REVENUECAT ===');
      dev.log('User ID: $userId');
      
      // Step 1: Identify user (this will merge/restore purchases)
      final customerInfo = await SubscriptionService.identifyUser(userId);
      if (customerInfo != null) {
        final activeEntitlements = customerInfo.entitlements.active;
        dev.log('✓ RevenueCat user identified successfully');
        dev.log('Active entitlements: ${activeEntitlements.keys.toList()}');
        
        // Step 2: If no active subscriptions found, try restoring purchases
        // This helps if purchases were made on another device or before linking
        if (activeEntitlements.isEmpty) {
          dev.log('⚠ No active subscriptions found, attempting to restore purchases...');
          try {
            final restoredInfo = await SubscriptionService.restorePurchases();
            if (restoredInfo != null && restoredInfo.entitlements.active.isNotEmpty) {
              dev.log('✓ Found subscriptions after restore!');
              dev.log('Active entitlements after restore: ${restoredInfo.entitlements.active.keys.toList()}');
            } else {
              dev.log('⚠ No subscriptions found after restore');
            }
          } catch (e) {
            dev.log('Error restoring purchases: $e');
          }
        } else {
          dev.log('✓ User has active subscription: ${activeEntitlements.keys.first}');
        }
        
        // Sync subscription status to Firestore after identification
        // This ensures premium status is persisted even if RevenueCat fails later
        try {
          await SubscriptionService.refreshCustomerInfo();
          dev.log('✓ Subscription status synced to Firestore after identification');
        } catch (e) {
          dev.log('⚠ Error syncing subscription to Firestore after identification: $e');
          // Don't fail identification if Firestore sync fails
        }
        
        _identifiedUsers.add(userId);
      } else {
        dev.log('✗ Failed to identify user in RevenueCat');
      }
      completer.complete();
    } catch (e) {
      dev.log('✗ Error identifying user in RevenueCat: $e');
      completer.completeError(e);
    } finally {
      _revenueCatIdentificationCompleters.remove(userId);
    }
  }

  /// Wait for RevenueCat identification to complete for current user
  /// Call this before checking subscription status
  Future<void> ensureRevenueCatIdentification() async {
    final user = _auth.currentUser;
    if (user == null) {
      dev.log('No user logged in, skipping RevenueCat identification');
      return;
    }

    // If already identified, return immediately
    if (_identifiedUsers.contains(user.uid)) {
      return;
    }

    // Wait for identification to complete
    if (_revenueCatIdentificationCompleters.containsKey(user.uid)) {
      await _revenueCatIdentificationCompleters[user.uid]!.future;
      return;
    }

    // If not started, start it now and wait
    await _identifyUserInRevenueCat(user.uid);
  }

  /// Check if data has been loaded for the current user
  Future<bool> hasLoadedDataForCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final prefs = await SharedPreferences.getInstance();
    final key = 'data_loaded_for_user_${user.uid}';
    return prefs.getBool(key) ?? false;
  }

  /// Mark that data has been loaded for the current user
  Future<void> markDataLoadedForCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final key = 'data_loaded_for_user_${user.uid}';
    await prefs.setBool(key, true);
    dev.log('Marked data as loaded for user: ${user.uid}');
  }

  /// Clear the data loaded flag when user logs out
  Future<void> clearDataLoadedFlag() async {
    final prefs = await SharedPreferences.getInstance();
    final user = _auth.currentUser;

    if (user != null) {
      final key = 'data_loaded_for_user_${user.uid}';
      await prefs.remove(key);
    }
  }

  /// Load user data after login and show a loading dialog
  /// Returns a stream of fetch status updates for the loading bar
  Stream<DataFetchStatus> loadUserDataAfterLogin(BuildContext context) async* {
    // Get the current user
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      yield const DataFetchError('No authenticated user found');
      return;
    }

    // Check if this is a new user by comparing creation and last sign-in times
    final isNewUser = user.metadata.creationTime?.isAtSameMomentAs(
            user.metadata.lastSignInTime ?? DateTime.now()) ??
        false;

    // Skip data fetching for new users since they won't have any data yet
    if (isNewUser) {
      dev.log('New user detected, skipping data fetch');
      // Mark as loaded so we don't try to fetch again
      await markDataLoadedForCurrentUser();
      yield const DataFetchSuccess();
      return;
    }

    // Check if data has already been loaded for this user
    final hasLoadedData = await hasLoadedDataForCurrentUser();
    if (hasLoadedData) {
      dev.log('Data has already been loaded for current user, skipping...');
      yield const DataFetchSuccess();
      return;
    }

    try {
      // CRITICAL: First identify user in RevenueCat to restore purchases
      // This must happen before checking subscription status
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        dev.log('Identifying user in RevenueCat before data fetch: ${user.uid}');
        await SubscriptionService.identifyUser(user.uid);
      }

      // Start the data fetching process
      final fetchStream = DataFetchingService.instance.fetchUserData();

      // Forward all status updates from the data fetching service
      await for (final status in fetchStream) {
        yield status;

        // When fetch is complete, mark data as loaded for this user
        if (status is DataFetchSuccess) {
          await markDataLoadedForCurrentUser();

          // Trigger refresh of expenses and incomes if context is still mounted
          if (context.mounted) {
            _refreshData(context);
          }
        }
      }
    } catch (e) {
      dev.log('Error loading user data: $e');
      yield DataFetchError(e.toString());
    }
  }

  /// Refresh expenses, incomes, budgets, and subscription status after successful data fetch
  void _refreshData(BuildContext context) {
    // Add a short delay to ensure everything is ready
    Future.delayed(const Duration(milliseconds: 300), () {
      try {
        if (context.mounted) {
          // Refresh expenses and incomes
          context.read<ExpenseListBloc>().add(const LoadExpenses());
          context.read<IncomeListBloc>().add(const LoadIncomes());

          // Refresh budgets
          try {
            context.read<BudgetBloc>().add(const LoadBudget());
            dev.log('Triggered refresh of budgets after data fetch');
          } catch (e) {
            dev.log('Error refreshing budgets (may not be available in context): $e');
          }

          // Refresh subscription status to ensure premium features are available
          // Force refresh to get latest status from RevenueCat after login
          try {
            context.read<SubscriptionCubit>().checkProStatus(forceRefresh: true);
            dev.log('Triggered refresh of subscription status after data fetch');
          } catch (e) {
            dev.log('Error refreshing subscription status (may not be available in context): $e');
          }

          dev.log('Triggered refresh of expenses, incomes, budgets, and subscription after data fetch');
        }
      } catch (e) {
        dev.log('Error refreshing data after fetch: $e');
      }
    });
  }

  /// Clear any resources
  void dispose() {
    _authStateSubscription?.cancel();
    _isInitialized = false;
  }

  /// Clear any cached Google credentials to prevent sign-in issues
  Future<void> _clearCachedGoogleCredentials() async {
    try {
      // We'll import these directly to avoid adding dependencies to this file
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;
      await googleSignIn.signOut();
      dev.log('Cleared cached Google credentials on startup');
    } catch (e) {
      dev.log('Error clearing Google credentials: $e');
      // Continue even if clearing fails
    }
  }

  /// Create or backfill the user document in Firestore under `users/{uid}`.
  ///
  /// - Writes `name`, `email`, `photoUrl`, `createdAt`, `updatedAt`.
  /// - Uses merge to avoid overwriting existing values.
  /// - Backfills only missing/empty fields for existing users.
  Future<void> _ensureUserDocument(User firebaseUser) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final docRef = firestore.collection('users').doc(firebaseUser.uid);

      final snapshot = await docRef.get();

      // Prefer auth metadata for createdAt, fallback to now
      final DateTime createdAtFromAuth =
          firebaseUser.metadata.creationTime ?? DateTime.now();

      // Prepare base values (nullable-safe). We do not write empty strings
      // unless they are actually provided; nulls will be skipped below.
      final String? email = firebaseUser.email?.trim().isEmpty == true
          ? null
          : firebaseUser.email;
      final String? name = firebaseUser.displayName?.trim().isEmpty == true
          ? null
          : firebaseUser.displayName;
      final String? photoUrl = firebaseUser.photoURL?.trim().isEmpty == true
          ? null
          : firebaseUser.photoURL;

      if (!snapshot.exists) {
        // New: create full document following expected field names
        final Map<String, dynamic> data = {
          'id': firebaseUser.uid,
          if (name != null) 'displayName': name,
          if (email != null) 'email': email,
          if (photoUrl != null) 'photoUrl': photoUrl,
          'emailVerified': firebaseUser.emailVerified,
          'created_at': createdAtFromAuth,
          'updated_at': FieldValue.serverTimestamp(),
          'isDeleted': false,
        };
        await docRef.set(data, SetOptions(merge: true));
        dev.log('Created user document for ${firebaseUser.uid}');
        return;
      }

      // Existing: only backfill missing/empty fields
      final Map<String, dynamic>? existing = snapshot.data();
      Map<String, dynamic> update = {};

      bool isMissing(dynamic v) =>
          v == null || (v is String && v.trim().isEmpty);

      // Backfill display name: prefer auth displayName, fallback from legacy 'name'
      final String? legacyName = (existing?['name'] is String &&
              (existing?['name'] as String).trim().isNotEmpty)
          ? (existing?['name'] as String)
          : null;
      if (isMissing(existing?['displayName'])) {
        final preferredName = name ?? legacyName;
        if (preferredName != null) update['displayName'] = preferredName;
      }
      if (isMissing(existing?['email']) && email != null)
        update['email'] = email;
      if (isMissing(existing?['photoUrl']) && photoUrl != null) {
        update['photoUrl'] = photoUrl;
      }
      if (isMissing(existing?['id'])) {
        update['id'] = firebaseUser.uid;
      }
      // Keep emailVerified in sync if missing
      if (existing?['emailVerified'] == null) {
        update['emailVerified'] = firebaseUser.emailVerified;
      }
      // Backfill created_at if missing (also support legacy 'createdAt')
      final hasCreatedAtSnake = existing?['created_at'] != null;
      final hasCreatedAtCamel = existing?['createdAt'] != null;
      if (!hasCreatedAtSnake && !hasCreatedAtCamel) {
        update['created_at'] = createdAtFromAuth;
      }
      // Always refresh updated_at timestamp
      update['updated_at'] = FieldValue.serverTimestamp();

      if (update.isNotEmpty) {
        await docRef.set(update, SetOptions(merge: true));
        dev.log(
            'Backfilled user document for ${firebaseUser.uid}: ${update.keys.toList()}');
      }
    } catch (e, st) {
      // Never throw; just log. This should not break sign-in flow.
      dev.log('Failed to ensure user document: $e', stackTrace: st);
    }
  }

  /// Sync the current Firebase user profile into Firestore and optionally
  /// mark the account as verified. This is safe to call multiple times.
  Future<void> syncUserProfile({bool markVerified = false}) async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) return;

      final firestore = FirebaseFirestore.instance;
      final docRef = firestore.collection('users').doc(firebaseUser.uid);

      final String? email = firebaseUser.email?.trim().isEmpty == true
          ? null
          : firebaseUser.email;
      final String? name = firebaseUser.displayName?.trim().isEmpty == true
          ? null
          : firebaseUser.displayName;
      final String? photoUrl = firebaseUser.photoURL?.trim().isEmpty == true
          ? null
          : firebaseUser.photoURL;

      final bool verified = markVerified || firebaseUser.emailVerified;

      final Map<String, dynamic> update = {
        if (name != null) 'displayName': name,
        if (email != null) 'email': email,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'emailVerified': verified,
        if (verified) 'verified_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      await docRef.set(update, SetOptions(merge: true));
      dev.log('Synced user profile for ${firebaseUser.uid}');
    } catch (e, st) {
      dev.log('Failed to sync user profile: $e', stackTrace: st);
    }
  }
}
