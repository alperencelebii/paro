import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../models/premium_subscription_model.dart';
import '../repository/firestore_subscription_repository.dart';

class SubscriptionService {
  static bool _isConfigured = false;
  static final FirestoreSubscriptionRepository _firestoreRepo =
      FirestoreSubscriptionRepository();

  /// Check if RevenueCat is configured
  static bool get isConfigured => _isConfigured;

  /// Configure Reveenue Cat
  static Future<void> configureRevenueCat(String apiKey) async {
    // Only configure if we have a valid API key
    if (apiKey.isEmpty || apiKey.trim().isEmpty) {
      log('Warning: RevenueCat API key is empty. RevenueCat will not be configured.');
      _isConfigured = false;
      return;
    }

    try {
      await Purchases.configure(PurchasesConfiguration(apiKey));
      _isConfigured = true;
      log('RevenueCat configured successfully');
    } catch (e) {
      _isConfigured = false;
      log('Error Configuring RevenueCat: $e');
      rethrow;
    }
  }

  /// Fetch Offering
  static Future<Offerings?> fetchOffering() async {
    if (!_isConfigured) {
      log('Error: RevenueCat is not configured. Cannot fetch offerings.');
      return null;
    }

    try {
      Offerings offerings = await Purchases.getOfferings();
      log('Offering Fetched SuccessFully');

      return offerings;
    } catch (e) {
      log('Error Fetching Offering: $e');
      return null;
    }
  }

  /// Purchase a Packages
  static Future<CustomerInfo?> customerInfo(Package package) async {
    if (!_isConfigured) {
      log('Error: RevenueCat is not configured. Cannot get customer info.');
      return null;
    }

    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();

      log('Customer Info Fetched');
      return customerInfo;
    } catch (e) {
      log('Error CustomerInfo: $e');
      return null;
    }
  }

  /// Sync subscription data from RevenueCat to Firestore
  static Future<void> _syncSubscriptionToFirestore(
      CustomerInfo? customerInfo) async {
    log('[SubscriptionService] ===== SYNC TO FIRESTORE START =====');

    if (customerInfo == null) {
      log('[SubscriptionService] ✗ No customer info provided, cannot sync to Firestore');
      log('[SubscriptionService] ===== SYNC TO FIRESTORE END (NO DATA) =====');
      return;
    }

    try {
      log('[SubscriptionService] Step 1: Analyzing RevenueCat entitlements...');
      final activeEntitlements = customerInfo.entitlements.active;
      final allEntitlements = customerInfo.entitlements.all;
      log('[SubscriptionService] Active entitlements: ${activeEntitlements.keys.toList()}');
      log('[SubscriptionService] All entitlements: ${allEntitlements.keys.toList()}');

      final hasPro = activeEntitlements.containsKey('pro');
      final hasPas = activeEntitlements.containsKey('pas');
      final isPremium = hasPro || hasPas;

      log('[SubscriptionService] Premium status: isPremium=$isPremium, hasPro=$hasPro, hasPas=$hasPas');

      if (isPremium) {
        log('[SubscriptionService] Step 2: User has premium subscription, extracting details...');
        // Get the active entitlement (prefer 'pas' over 'pro')
        final entitlement =
            hasPas ? activeEntitlements['pas']! : activeEntitlements['pro']!;

        log('[SubscriptionService] Selected entitlement: ${entitlement.identifier}');
        log('[SubscriptionService] Product ID: ${entitlement.productIdentifier}');
        log('[SubscriptionService] Expiration: ${entitlement.expirationDate}');
        log('[SubscriptionService] Will renew: ${entitlement.willRenew}');
        log('[SubscriptionService] Store: ${entitlement.store.name}');

        final subscription = PremiumSubscriptionModel(
          isPremium: true,
          planId: entitlement.identifier, // 'pro' or 'pas'
          productIdentifier: entitlement.productIdentifier,
          purchaseDate: entitlement.latestPurchaseDate as DateTime?,
          expirationDate: entitlement.expirationDate as DateTime?,
          willRenew: entitlement.willRenew,
          store: entitlement.store.name,
          lastSyncedAt: DateTime.now(),
        );

        log('[SubscriptionService] Step 3: Saving premium subscription to Firestore...');
        await _firestoreRepo.savePremiumSubscription(subscription);
        log('[SubscriptionService] ✓ Successfully synced premium subscription to Firestore: plan=${subscription.planId}');
        log('[SubscriptionService] ===== SYNC TO FIRESTORE SUCCESS (PREMIUM) =====');
      } else {
        log('[SubscriptionService] Step 2: User does NOT have premium subscription');
        log('[SubscriptionService] Step 3: Updating Firestore to reflect non-premium status...');
        // No active subscription - update Firestore to reflect this
        await _firestoreRepo.updateSubscriptionStatus(isPremium: false);
        log('[SubscriptionService] ✓ Successfully synced non-premium status to Firestore');
        log('[SubscriptionService] ===== SYNC TO FIRESTORE SUCCESS (NON-PREMIUM) =====');
      }
    } catch (e, stackTrace) {
      log(
        '[SubscriptionService] ✗ CRITICAL ERROR syncing subscription to Firestore: $e',
        error: e,
        stackTrace: stackTrace,
      );
      log('[SubscriptionService] Note: This is a backup system, app will continue normally');
      log('[SubscriptionService] ===== SYNC TO FIRESTORE END (ERROR) =====');
      // Don't throw - Firestore sync is a backup, shouldn't break the app
    }
  }

  /// Is Pro User?
  /// Checks RevenueCat first, falls back to Firestore if RevenueCat fails or isn't configured
  static Future<bool> isProUser() async {
    log('[SubscriptionService] ===== IS PRO USER CHECK START =====');

    // Try RevenueCat first if configured
    if (_isConfigured) {
      log('[SubscriptionService] Step 1: RevenueCat is configured, checking RevenueCat first...');
      try {
        log('[SubscriptionService] Step 1.1: Fetching customer info from RevenueCat...');
        // Force refresh customer info from RevenueCat to get latest subscription status
        CustomerInfo customerInfo = await Purchases.getCustomerInfo()
            .timeout(const Duration(seconds: 10), onTimeout: () {
          log('[SubscriptionService] ✗ RevenueCat getCustomerInfo timed out');
          throw TimeoutException('RevenueCat operation timed out');
        });

        log('[SubscriptionService] ✓ Customer info retrieved from RevenueCat');
        log('[SubscriptionService] RevenueCat User ID: ${customerInfo.originalAppUserId}');

        // Log all entitlements for debugging
        log('[SubscriptionService] All entitlements: ${customerInfo.entitlements.all.keys.toList()}');
        log('[SubscriptionService] Active entitlements: ${customerInfo.entitlements.active.keys.toList()}');

        final isPro = customerInfo.entitlements.active.containsKey('pro') ||
            customerInfo.entitlements.active.containsKey('pas');

        log('[SubscriptionService] Step 1.2: Analyzing premium status...');
        log('[SubscriptionService] Has Pro entitlement: ${customerInfo.entitlements.active.containsKey('pro')}');
        log('[SubscriptionService] Has Pas entitlement: ${customerInfo.entitlements.active.containsKey('pas')}');
        log('[SubscriptionService] Final isPro result: $isPro');

        if (isPro) {
          final activeKeys = customerInfo.entitlements.active.keys.toList();
          log('[SubscriptionService] ✓ User IS Pro/Premium with entitlements: $activeKeys');

          // Sync to Firestore for backup (non-blocking)
          log('[SubscriptionService] Step 1.3: Triggering Firestore sync (non-blocking)...');
          unawaited(_syncSubscriptionToFirestore(customerInfo));

          log('[SubscriptionService] ===== IS PRO USER CHECK SUCCESS (PREMIUM) =====');
          return true;
        } else {
          log('[SubscriptionService] ✗ User is NOT Pro/Premium according to RevenueCat');
          log('[SubscriptionService] Active entitlements: ${customerInfo.entitlements.active.keys.toList()}');

          // Sync non-premium status to Firestore (non-blocking)
          log('[SubscriptionService] Step 1.3: Syncing non-premium status to Firestore (non-blocking)...');
          unawaited(_syncSubscriptionToFirestore(customerInfo));

          // Still check Firestore as fallback in case RevenueCat is out of sync
          log('[SubscriptionService] Step 1.4: Checking Firestore as fallback (with timeout)...');
          try {
            final firestoreResult = await _checkFirestorePremiumStatus()
                .timeout(const Duration(seconds: 3), onTimeout: () {
              log('[SubscriptionService] ⚠ Firestore check timed out, assuming not premium');
              return false;
            });
            log('[SubscriptionService] Firestore fallback result: $firestoreResult');
            log('[SubscriptionService] ===== IS PRO USER CHECK END (NOT PREMIUM, FIRESTORE CHECKED) =====');
            return firestoreResult;
          } catch (e, stackTrace) {
            log(
              '[SubscriptionService] ✗ Error checking Firestore premium status: $e',
              error: e,
              stackTrace: stackTrace,
            );
            log('[SubscriptionService] ===== IS PRO USER CHECK END (NOT PREMIUM, FIRESTORE ERROR) =====');
            return false;
          }
        }
      } on TimeoutException catch (e) {
        log('[SubscriptionService] ✗ RevenueCat operation timed out: $e');
        log('[SubscriptionService] Falling back to Firestore...');
        // Fall through to Firestore check
      } catch (e, stackTrace) {
        log(
          '[SubscriptionService] ✗ CRITICAL ERROR checking RevenueCat: $e',
          error: e,
          stackTrace: stackTrace,
        );
        log('[SubscriptionService] Falling back to Firestore...');
        // Fall through to Firestore check
      }
    } else {
      log('[SubscriptionService] Step 1: RevenueCat is NOT configured');
      log('[SubscriptionService] Checking Firestore for premium status...');
    }

    // Fallback to Firestore with timeout
    log('[SubscriptionService] Step 2: Using Firestore as primary/fallback source...');
    try {
      final result = await _checkFirestorePremiumStatus()
          .timeout(const Duration(seconds: 3), onTimeout: () {
        log('[SubscriptionService] ⚠ Firestore check timed out, assuming not premium');
        return false;
      });
      log('[SubscriptionService] Firestore result: $result');
      log('[SubscriptionService] ===== IS PRO USER CHECK END (FIRESTORE: $result) =====');
      return result;
    } catch (e, stackTrace) {
      log(
        '[SubscriptionService] ✗ CRITICAL ERROR checking Firestore premium status: $e',
        error: e,
        stackTrace: stackTrace,
      );
      log('[SubscriptionService] ===== IS PRO USER CHECK END (ERROR, ASSUMING NOT PREMIUM) =====');
      return false;
    }
  }

  /// Check premium status from Firestore (fallback method)
  static Future<bool> _checkFirestorePremiumStatus() async {
    log('[SubscriptionService] ===== CHECK FIRESTORE PREMIUM STATUS START =====');
    try {
      log('[SubscriptionService] Step 1: Fetching subscription from Firestore...');
      final subscription = await _firestoreRepo.getPremiumSubscription();

      if (subscription == null) {
        log('[SubscriptionService] ✗ No premium subscription found in Firestore');
        log('[SubscriptionService] ===== CHECK FIRESTORE PREMIUM STATUS END (NO DATA) =====');
        return false;
      }

      log('[SubscriptionService] ✓ Subscription data retrieved from Firestore');
      log('[SubscriptionService] Step 2: Validating subscription status...');

      // Check if subscription is still active (not expired)
      final isActive = subscription.isActive;
      log('[SubscriptionService] Subscription details:');
      log('[SubscriptionService]   - isPremium: ${subscription.isPremium}');
      log('[SubscriptionService]   - isActive: $isActive');
      log('[SubscriptionService]   - planId: ${subscription.planId}');
      log('[SubscriptionService]   - expirationDate: ${subscription.expirationDate}');
      log('[SubscriptionService]   - willRenew: ${subscription.willRenew}');
      log('[SubscriptionService]   - lastSyncedAt: ${subscription.lastSyncedAt}');

      if (subscription.isPremium && isActive) {
        log('[SubscriptionService] ✓ User IS Premium according to Firestore (active subscription)');
        log('[SubscriptionService] ===== CHECK FIRESTORE PREMIUM STATUS END (PREMIUM) =====');
        return true;
      } else if (subscription.isPremium && !isActive) {
        log('[SubscriptionService] ⚠ User has premium subscription in Firestore but it has EXPIRED');
        log('[SubscriptionService] Step 3: Updating Firestore to reflect expired status...');
        // Update Firestore to reflect expired status (non-blocking)
        unawaited(_firestoreRepo.updateSubscriptionStatus(isPremium: false));
        log('[SubscriptionService] ===== CHECK FIRESTORE PREMIUM STATUS END (EXPIRED) =====');
        return false;
      } else {
        log('[SubscriptionService] ✗ User is NOT premium according to Firestore');
        log('[SubscriptionService] ===== CHECK FIRESTORE PREMIUM STATUS END (NOT PREMIUM) =====');
        return false;
      }
    } catch (e, stackTrace) {
      log(
        '[SubscriptionService] ✗ CRITICAL ERROR checking Firestore premium status: $e',
        error: e,
        stackTrace: stackTrace,
      );
      log('[SubscriptionService] ===== CHECK FIRESTORE PREMIUM STATUS END (ERROR) =====');
      return false;
    }
  }

  /// Refresh customer info from RevenueCat (useful after login)
  static Future<CustomerInfo?> refreshCustomerInfo() async {
    log('[SubscriptionService] ===== REFRESH CUSTOMER INFO START =====');

    if (!_isConfigured) {
      log('[SubscriptionService] ✗ RevenueCat is not configured. Cannot refresh customer info.');
      log('[SubscriptionService] ===== REFRESH CUSTOMER INFO END (NOT CONFIGURED) =====');
      return null;
    }

    try {
      log('[SubscriptionService] Step 1: Fetching customer info from RevenueCat...');
      // Force sync with RevenueCat servers
      final customerInfo = await Purchases.getCustomerInfo()
          .timeout(const Duration(seconds: 10), onTimeout: () {
        log('[SubscriptionService] ✗ getCustomerInfo timed out');
        throw TimeoutException('RevenueCat getCustomerInfo timed out');
      });

      log('[SubscriptionService] ✓ Customer info refreshed from RevenueCat');
      log('[SubscriptionService] RevenueCat User ID: ${customerInfo.originalAppUserId}');
      log('[SubscriptionService] Active entitlements: ${customerInfo.entitlements.active.keys.toList()}');

      // Sync to Firestore (non-blocking)
      log('[SubscriptionService] Step 2: Triggering Firestore sync (non-blocking)...');
      unawaited(_syncSubscriptionToFirestore(customerInfo));

      log('[SubscriptionService] ===== REFRESH CUSTOMER INFO SUCCESS =====');
      return customerInfo;
    } on TimeoutException catch (e) {
      log('[SubscriptionService] ✗ Refresh customer info timed out: $e');
      log('[SubscriptionService] ===== REFRESH CUSTOMER INFO END (TIMEOUT) =====');
      return null;
    } catch (e, stackTrace) {
      log(
        '[SubscriptionService] ✗ CRITICAL ERROR refreshing customer info: $e',
        error: e,
        stackTrace: stackTrace,
      );
      log('[SubscriptionService] ===== REFRESH CUSTOMER INFO END (ERROR) =====');
      return null;
    }
  }

  /// Identify user in RevenueCat with their Firebase UID
  /// This is CRITICAL - without this, RevenueCat can't restore purchases
  /// If user already has purchases, this will merge/restore them
  static Future<CustomerInfo?> identifyUser(String appUserId) async {
    log('[SubscriptionService] ===== IDENTIFY USER IN REVENUECAT START =====');
    log('[SubscriptionService] Firebase UID: $appUserId');

    if (!_isConfigured) {
      log('[SubscriptionService] ✗ RevenueCat is not configured. Cannot identify user.');
      log('[SubscriptionService] ===== IDENTIFY USER END (NOT CONFIGURED) =====');
      return null;
    }

    try {
      log('[SubscriptionService] Step 1: Getting current customer info...');
      // First, get current customer info to see if there's an existing anonymous user
      final currentCustomerInfo = await Purchases.getCustomerInfo()
          .timeout(const Duration(seconds: 10), onTimeout: () {
        log('[SubscriptionService] ✗ getCustomerInfo timed out during identification');
        throw TimeoutException('RevenueCat getCustomerInfo timed out');
      });

      final currentUserId = currentCustomerInfo.originalAppUserId;
      final hasAnonymousPurchases =
          currentCustomerInfo.entitlements.active.isNotEmpty &&
              currentUserId != appUserId;

      log('[SubscriptionService] Current RevenueCat User ID: $currentUserId');
      log('[SubscriptionService] Current active entitlements: ${currentCustomerInfo.entitlements.active.keys.toList()}');
      log('[SubscriptionService] Has anonymous purchases: $hasAnonymousPurchases');

      if (hasAnonymousPurchases) {
        log('[SubscriptionService] ⚠ Found anonymous purchases! These will be merged with Firebase UID');
      }

      // Log in with Firebase UID - this will:
      // 1. If user has purchases with this UID, restore them
      // 2. If user has anonymous purchases, merge them with this UID
      // 3. If new user, create account with this UID
      log('[SubscriptionService] Step 2: Calling Purchases.logIn($appUserId)...');
      final logInResult = await Purchases.logIn(appUserId)
          .timeout(const Duration(seconds: 15), onTimeout: () {
        log('[SubscriptionService] ✗ logIn timed out');
        throw TimeoutException('RevenueCat logIn timed out');
      });

      final customerInfo = logInResult.customerInfo;

      log('[SubscriptionService] ✓ User identified in RevenueCat');
      log('[SubscriptionService]   - Created new account: ${logInResult.created}');
      log('[SubscriptionService]   - RevenueCat User ID: ${customerInfo.originalAppUserId}');
      log('[SubscriptionService]   - Active entitlements: ${customerInfo.entitlements.active.keys.toList()}');
      log('[SubscriptionService]   - All entitlements: ${customerInfo.entitlements.all.keys.toList()}');

      // If we had anonymous purchases and they're now merged, log it
      if (hasAnonymousPurchases &&
          customerInfo.entitlements.active.isNotEmpty) {
        log('[SubscriptionService] ✓ Anonymous purchases successfully merged with Firebase UID!');
      }

      if (customerInfo.entitlements.active.isNotEmpty) {
        log('[SubscriptionService] ✓ Found active subscription after identification!');
      } else {
        log('[SubscriptionService] ⚠ No active subscriptions found after identification');
        log('[SubscriptionService]   Possible reasons:');
        log('[SubscriptionService]   1. User has no active subscription');
        log('[SubscriptionService]   2. Purchase was made with different user ID');
        log('[SubscriptionService]   3. Subscription expired');
        log('[SubscriptionService]   4. Purchase needs to be restored from store');

        // Try restoring purchases as a fallback
        log('[SubscriptionService] Step 3: Attempting to restore purchases from store...');
        try {
          final restoredInfo = await Purchases.restorePurchases()
              .timeout(const Duration(seconds: 10), onTimeout: () {
            log('[SubscriptionService] ✗ restorePurchases timed out');
            throw TimeoutException('RevenueCat restorePurchases timed out');
          });

          if (restoredInfo.entitlements.active.isNotEmpty) {
            log('[SubscriptionService] ✓ Found subscriptions after restore!');
            log('[SubscriptionService] Active entitlements after restore: ${restoredInfo.entitlements.active.keys.toList()}');
            // Sync restored subscription to Firestore (non-blocking)
            log('[SubscriptionService] Step 4: Syncing restored subscription to Firestore (non-blocking)...');
            unawaited(_syncSubscriptionToFirestore(restoredInfo));
            log('[SubscriptionService] ===== IDENTIFY USER SUCCESS (RESTORED) =====');
            return restoredInfo;
          } else {
            log('[SubscriptionService] No subscriptions found after restore');
          }
        } on TimeoutException catch (e) {
          log('[SubscriptionService] ✗ Restore purchases timed out: $e');
        } catch (e, stackTrace) {
          log(
            '[SubscriptionService] ✗ Error restoring purchases: $e',
            error: e,
            stackTrace: stackTrace,
          );
        }
      }

      // Sync subscription status to Firestore after identification (non-blocking)
      log('[SubscriptionService] Step 4: Syncing subscription status to Firestore (non-blocking)...');
      unawaited(_syncSubscriptionToFirestore(customerInfo));

      log('[SubscriptionService] ===== IDENTIFY USER SUCCESS =====');
      return customerInfo;
    } on TimeoutException catch (e) {
      log('[SubscriptionService] ✗ Identify user operation timed out: $e');
      log('[SubscriptionService] ===== IDENTIFY USER END (TIMEOUT) =====');
      return null;
    } catch (e, stackTrace) {
      log(
        '[SubscriptionService] ✗ CRITICAL ERROR identifying user in RevenueCat: $e',
        error: e,
        stackTrace: stackTrace,
      );
      log('[SubscriptionService] ===== IDENTIFY USER END (ERROR) =====');
      return null;
    }
  }

  /// Restore purchases - useful for restoring purchases made on another device
  /// or if purchases aren't showing up
  static Future<CustomerInfo?> restorePurchases() async {
    log('[SubscriptionService] ===== RESTORE PURCHASES START =====');

    if (!_isConfigured) {
      log('[SubscriptionService] ✗ RevenueCat is not configured. Cannot restore purchases.');
      log('[SubscriptionService] ===== RESTORE PURCHASES END (NOT CONFIGURED) =====');
      return null;
    }

    try {
      log('[SubscriptionService] Step 1: Calling Purchases.restorePurchases()...');
      final customerInfo = await Purchases.restorePurchases()
          .timeout(const Duration(seconds: 15), onTimeout: () {
        log('[SubscriptionService] ✗ restorePurchases timed out');
        throw TimeoutException('RevenueCat restorePurchases timed out');
      });

      log('[SubscriptionService] ✓ Purchases restored');
      log('[SubscriptionService] RevenueCat User ID: ${customerInfo.originalAppUserId}');
      log('[SubscriptionService] Active entitlements: ${customerInfo.entitlements.active.keys.toList()}');
      log('[SubscriptionService] All entitlements: ${customerInfo.entitlements.all.keys.toList()}');

      if (customerInfo.entitlements.active.isNotEmpty) {
        log('[SubscriptionService] ✓ Found ${customerInfo.entitlements.active.length} active subscription(s)');
      } else {
        log('[SubscriptionService] ⚠ No active subscriptions found after restore');
      }

      // Sync restored subscription to Firestore (non-blocking)
      log('[SubscriptionService] Step 2: Syncing restored subscription to Firestore (non-blocking)...');
      unawaited(_syncSubscriptionToFirestore(customerInfo));

      log('[SubscriptionService] ===== RESTORE PURCHASES SUCCESS =====');
      return customerInfo;
    } on TimeoutException catch (e) {
      log('[SubscriptionService] ✗ Restore purchases timed out: $e');
      log('[SubscriptionService] ===== RESTORE PURCHASES END (TIMEOUT) =====');
      return null;
    } catch (e, stackTrace) {
      log(
        '[SubscriptionService] ✗ CRITICAL ERROR restoring purchases: $e',
        error: e,
        stackTrace: stackTrace,
      );
      log('[SubscriptionService] ===== RESTORE PURCHASES END (ERROR) =====');
      return null;
    }
  }

  /// Log out user from RevenueCat (call on logout)
  static Future<CustomerInfo?> logOutUser() async {
    if (!_isConfigured) {
      log('Warning: RevenueCat is not configured. Cannot log out user.');
      return null;
    }

    try {
      // First check if user is anonymous by getting customer info
      try {
        final customerInfo = await Purchases.getCustomerInfo();
        final appUserId = customerInfo.originalAppUserId;

        // If user is anonymous, don't try to log out (RevenueCat doesn't allow this)
        // Anonymous users have IDs starting with '$RCAnonymousID:'
        if (appUserId.isEmpty || appUserId.startsWith('\$RCAnonymousID:')) {
          log('User is anonymous in RevenueCat, skipping logout');
          return null;
        }
      } catch (e) {
        // If we can't get customer info, proceed with logout attempt
        log('Could not check customer info before logout: $e');
      }

      log('Logging out user from RevenueCat');
      final customerInfo = await Purchases.logOut();
      log('User logged out from RevenueCat');

      // Clear Firestore subscription data on logout
      unawaited(_firestoreRepo.clearPremiumSubscription());

      return customerInfo;
    } on PlatformException catch (e) {
      // Handle specific error: trying to log out anonymous user
      if (e.code == '22' ||
          e.message?.contains('anonymous') == true ||
          e.message?.contains('LogOutWithAnonymousUserError') == true) {
        log('User is anonymous in RevenueCat, skipping logout (this is expected on app startup)');
        return null;
      }
      log('Error logging out user from RevenueCat: $e');
      return null;
    } catch (e) {
      log('Error logging out user from RevenueCat: $e');
      return null;
    }
  }

  /// Test method to verify subscription restoration
  /// Call this to manually test if subscription is being restored
  static Future<Map<String, dynamic>> testSubscriptionRestore(
      String userId) async {
    if (!_isConfigured) {
      log('Error: RevenueCat is not configured. Cannot test subscription restore.');
      return {
        'success': false,
        'error': 'RevenueCat is not configured',
      };
    }

    try {
      log('=== TESTING SUBSCRIPTION RESTORE ===');
      log('Firebase User ID: $userId');

      // Step 1: Check current state before identification
      log('\nStep 1: Checking current RevenueCat state...');
      final currentInfo = await Purchases.getCustomerInfo();
      log('   - Current RevenueCat User ID: ${currentInfo.originalAppUserId}');
      log('   - Current active entitlements: ${currentInfo.entitlements.active.keys.toList()}');

      // Step 2: Identify user
      log('\nStep 2: Identifying user in RevenueCat...');
      final logInResult = await Purchases.logIn(userId);
      log('✓ User identified. Created new account: ${logInResult.created}');

      // Step 3: Get customer info after identification
      log('\nStep 3: Fetching customer info after identification...');
      final customerInfo = logInResult.customerInfo;
      log('✓ Customer info fetched');
      log('   - RevenueCat User ID: ${customerInfo.originalAppUserId}');
      log('   - First Seen: ${customerInfo.firstSeen}');
      log('   - Request Date: ${customerInfo.requestDate}');

      // Step 4: Try restoring purchases (in case they're on another device)
      log('\nStep 4: Attempting to restore purchases...');
      try {
        final restoredInfo = await Purchases.restorePurchases();
        log('✓ Restore purchases completed');
        log('   - Active entitlements after restore: ${restoredInfo.entitlements.active.keys.toList()}');

        // Use restored info if it has more entitlements
        if (restoredInfo.entitlements.active.length >
            customerInfo.entitlements.active.length) {
          log('   - Found additional entitlements after restore!');
          return _buildTestResult(restoredInfo);
        }
      } catch (e) {
        log('   - Restore purchases error (may be normal): $e');
      }

      // Step 5: Check entitlements
      log('\nStep 5: Final entitlement check...');
      return _buildTestResult(customerInfo);
    } catch (e, stackTrace) {
      log('=== TEST FAILED ===');
      log('Error: $e');
      log('Stack trace: $stackTrace');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Map<String, dynamic> _buildTestResult(CustomerInfo customerInfo) {
    final allEntitlements = customerInfo.entitlements.all;
    final activeEntitlements = customerInfo.entitlements.active;

    log('   - All entitlements: ${allEntitlements.keys.toList()}');
    log('   - Active entitlements: ${activeEntitlements.keys.toList()}');

    // Check for pro/pas
    final hasPro = activeEntitlements.containsKey('pro');
    final hasPas = activeEntitlements.containsKey('pas');
    final isPremium = hasPro || hasPas;

    log('\nStep 6: Subscription status:');
    log('   - Has Pro: $hasPro');
    log('   - Has Pas: $hasPas');
    log('   - Is Premium: $isPremium');

    if (isPremium) {
      final entitlement =
          hasPas ? activeEntitlements['pas']! : activeEntitlements['pro']!;
      log('   - Product ID: ${entitlement.productIdentifier}');
      log('   - Is Active: ${entitlement.isActive}');
      log('   - Will Renew: ${entitlement.willRenew}');
      log('   - Expiration Date: ${entitlement.expirationDate}');
      log('   - Latest Purchase: ${entitlement.latestPurchaseDate}');
      log('   - Store: ${entitlement.store}');
    } else {
      log('   ⚠ NO ACTIVE SUBSCRIPTION FOUND');
      log('   Possible reasons:');
      log('   1. Subscription expired');
      log('   2. Purchase was made with different user ID');
      log('   3. Purchase was made before linking to Firebase UID');
      log('   4. Subscription is in sandbox and needs testing');
    }

    log('\n=== TEST COMPLETE ===');

    return {
      'success': true,
      'isPremium': isPremium,
      'hasPro': hasPro,
      'hasPas': hasPas,
      'activeEntitlements': activeEntitlements.keys.toList(),
      'allEntitlements': allEntitlements.keys.toList(),
      'originalAppUserId': customerInfo.originalAppUserId,
    };
  }
}
