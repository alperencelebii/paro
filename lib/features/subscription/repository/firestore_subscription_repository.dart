import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import '../models/premium_subscription_model.dart';

/// Repository for managing premium subscription data in Firestore
/// This serves as a backup/fallback when RevenueCat is unavailable
/// Uses offline-first approach with non-blocking operations
class FirestoreSubscriptionRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  static const Duration _timeoutDuration = Duration(seconds: 5);
  static const int _maxRetries = 3;
  static const Duration _initialRetryDelay = Duration(milliseconds: 500);

  FirestoreSubscriptionRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance {
    try {
      // Enable offline persistence
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      dev.log(
          '✓ FirestoreSubscriptionRepository initialized with offline persistence');
    } catch (e, stackTrace) {
      dev.log(
        '✗ Error initializing Firestore settings: $e',
        error: e,
        stackTrace: stackTrace,
      );
      // Continue anyway - Firestore will use default settings
    }
  }

  /// Get the subscription document reference for current user
  DocumentReference<Map<String, dynamic>> _getSubscriptionDoc() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('subscription')
        .doc('premium');
  }

  /// Check if error is a transient/unavailable error that should be retried
  bool _isTransientError(dynamic error) {
    if (error is FirebaseException) {
      return error.code == 'unavailable' ||
          error.code == 'deadline-exceeded' ||
          error.code == 'internal';
    }
    if (error is PlatformException) {
      final code = error.code.toString().toLowerCase();
      final message = error.message?.toString().toLowerCase() ?? '';
      return code.contains('unavailable') ||
          code.contains('deadline') ||
          message.contains('transient') ||
          message.contains('unavailable');
    }
    final errorString = error.toString().toLowerCase();
    return errorString.contains('unavailable') ||
        errorString.contains('transient') ||
        errorString.contains('deadline');
  }

  /// Get premium subscription data from Firestore (with retry logic and offline support)
  Future<PremiumSubscriptionModel?> getPremiumSubscription() async {
    dev.log(
        '[FirestoreSubscription] ===== GET PREMIUM SUBSCRIPTION START =====');
    try {
      final user = _auth.currentUser;
      if (user == null) {
        dev.log(
            '[FirestoreSubscription] ✗ No user authenticated, cannot get premium subscription');
        return null;
      }
      dev.log('[FirestoreSubscription] User authenticated: ${user.uid}');

      // Use serverAndCache which will try cache first, then server automatically
      // This handles the case where cache is unavailable but server is available
      DocumentSnapshot<Map<String, dynamic>>? doc;

      // Retry logic with exponential backoff for transient errors
      for (int attempt = 0; attempt <= _maxRetries; attempt++) {
        try {
          if (attempt > 0) {
            final delay = _initialRetryDelay * pow(2, attempt - 1);
            dev.log(
                '[FirestoreSubscription] Retry attempt $attempt/$_maxRetries after ${delay.inMilliseconds}ms delay...');
            await Future.delayed(delay);
          }

          dev.log(
              '[FirestoreSubscription] Step ${attempt + 1}: Attempting to read document (attempt ${attempt + 1}/${_maxRetries + 1})...');

          // Use serverAndCache: tries cache first, falls back to server if cache unavailable
          // This is better than forcing Source.cache which fails when cache is unavailable
          doc = await _getSubscriptionDoc()
              .get(const GetOptions(source: Source.serverAndCache))
              .timeout(_timeoutDuration, onTimeout: () {
            dev.log(
                '[FirestoreSubscription] ⚠ Read timeout after ${_timeoutDuration.inSeconds}s');
            throw TimeoutException('Firestore read timed out');
          });

          dev.log(
              '[FirestoreSubscription] ✓ Read successful, doc exists: ${doc.exists}, fromCache: ${doc.metadata.isFromCache}');
          break; // Success, exit retry loop
        } on TimeoutException catch (e) {
          dev.log('[FirestoreSubscription] ✗ Read timed out: $e');
          if (attempt == _maxRetries) {
            doc = null;
            break;
          }
          // Continue to retry
        } on FirebaseException catch (e, stackTrace) {
          if (e.code == 'not-found') {
            // Document doesn't exist - this is not an error, just no data
            dev.log(
                '[FirestoreSubscription] ⚠ Document not found (user may not have subscription)');
            doc = null;
            break;
          } else if (_isTransientError(e) && attempt < _maxRetries) {
            // Transient error - retry
            dev.log(
                '[FirestoreSubscription] ⚠ Transient error (${e.code}): ${e.message}, will retry...');
            // Continue to retry
          } else {
            // Non-transient error or max retries reached
            dev.log(
                '[FirestoreSubscription] ✗ Firestore error: ${e.code} - ${e.message}',
                error: e,
                stackTrace: stackTrace);
            doc = null;
            break;
          }
        } on PlatformException catch (e, stackTrace) {
          // Handle PlatformException which wraps Firebase errors
          final code = e.code.toString().toLowerCase();
          final message = e.message?.toString().toLowerCase() ?? '';

          if (code.contains('not-found') || message.contains('not found')) {
            // Document doesn't exist - this is not an error
            dev.log(
                '[FirestoreSubscription] ⚠ Document not found (user may not have subscription)');
            doc = null;
            break;
          } else if (_isTransientError(e) && attempt < _maxRetries) {
            // Transient error - retry
            dev.log(
                '[FirestoreSubscription] ⚠ Transient PlatformException (${e.code}): ${e.message}, will retry...');
            // Continue to retry
          } else {
            // Non-transient error or max retries reached
            dev.log(
                '[FirestoreSubscription] ✗ PlatformException: ${e.code} - ${e.message}',
                error: e,
                stackTrace: stackTrace);
            doc = null;
            break;
          }
        } catch (e, stackTrace) {
          // Handle other errors
          final errorString = e.toString().toLowerCase();
          if (errorString.contains('not found')) {
            dev.log(
                '[FirestoreSubscription] ⚠ Document not found (user may not have subscription)');
            doc = null;
            break;
          } else if (_isTransientError(e) && attempt < _maxRetries) {
            // Transient error - retry
            dev.log(
                '[FirestoreSubscription] ⚠ Transient error: $e, will retry...');
            // Continue to retry
          } else {
            // Non-transient error or max retries reached
            dev.log('[FirestoreSubscription] ✗ Error reading document: $e',
                error: e, stackTrace: stackTrace);
            doc = null;
            break;
          }
        }
      }

      if (doc == null) {
        dev.log(
            '[FirestoreSubscription] ===== GET PREMIUM SUBSCRIPTION END (NO DATA) =====');
        return null;
      }

      if (!doc.exists) {
        dev.log(
            '[FirestoreSubscription] Document does not exist (user has no subscription)');
        dev.log(
            '[FirestoreSubscription] ===== GET PREMIUM SUBSCRIPTION END (NO DATA) =====');
        return null;
      }

      dev.log(
          '[FirestoreSubscription] Step ${_maxRetries + 2}: Parsing subscription data...');
      final subscription = PremiumSubscriptionModel.fromFirestore(doc);
      dev.log(
          '[FirestoreSubscription] ✓ Retrieved premium subscription: isPremium=${subscription.isPremium}, isActive=${subscription.isActive}, expirationDate=${subscription.expirationDate}, fromCache=${doc.metadata.isFromCache}');
      dev.log(
          '[FirestoreSubscription] ===== GET PREMIUM SUBSCRIPTION SUCCESS =====');
      return subscription;
    } on TimeoutException catch (e) {
      dev.log('[FirestoreSubscription] ✗ Operation timed out: $e');
      dev.log(
          '[FirestoreSubscription] ===== GET PREMIUM SUBSCRIPTION END (TIMEOUT) =====');
      return null;
    } catch (e, stackTrace) {
      dev.log(
        '[FirestoreSubscription] ✗ CRITICAL ERROR getting premium subscription: $e',
        error: e,
        stackTrace: stackTrace,
      );
      dev.log(
          '[FirestoreSubscription] ===== GET PREMIUM SUBSCRIPTION END (ERROR) =====');
      return null;
    }
  }

  /// Save premium subscription data to Firestore (non-blocking with timeout)
  /// This is fire-and-forget - doesn't block the app
  Future<void> savePremiumSubscription(
      PremiumSubscriptionModel subscription) async {
    // Fire-and-forget - don't await, run in background
    unawaited(_savePremiumSubscriptionInternal(subscription));
  }

  /// Internal method to save subscription (with proper error handling)
  Future<void> _savePremiumSubscriptionInternal(
      PremiumSubscriptionModel subscription) async {
    dev.log(
        '[FirestoreSubscription] ===== SAVE PREMIUM SUBSCRIPTION START =====');
    dev.log(
        '[FirestoreSubscription] Subscription data: isPremium=${subscription.isPremium}, planId=${subscription.planId}');

    try {
      final user = _auth.currentUser;
      if (user == null) {
        dev.log(
            '[FirestoreSubscription] ✗ No user authenticated, cannot save premium subscription');
        return;
      }
      dev.log('[FirestoreSubscription] User authenticated: ${user.uid}');

      final docRef = _getSubscriptionDoc();
      dev.log('[FirestoreSubscription] Step 1: Getting existing document...');

      // Use serverAndCache which will try cache first, then server automatically
      DocumentSnapshot<Map<String, dynamic>>? existingDoc;
      try {
        existingDoc = await docRef
            .get(const GetOptions(source: Source.serverAndCache))
            .timeout(const Duration(seconds: 3));
        dev.log(
            '[FirestoreSubscription] ✓ Got existing doc: exists=${existingDoc.exists}, fromCache=${existingDoc.metadata.isFromCache}');
      } on FirebaseException catch (e) {
        // Handle specific Firestore errors gracefully
        if (e.code == 'not-found') {
          dev.log(
              '[FirestoreSubscription] ⚠ Document does not exist yet (will be created)');
          existingDoc = null;
        } else {
          dev.log(
              '[FirestoreSubscription] ⚠ Error getting existing doc: ${e.code} - ${e.message}, proceeding with save anyway');
          existingDoc = null;
        }
      } on PlatformException catch (e) {
        // Handle PlatformException which wraps Firebase errors
        final code = e.code.toString().toLowerCase();
        final message = e.message?.toString().toLowerCase() ?? '';
        if (code.contains('not-found') || message.contains('not found')) {
          dev.log(
              '[FirestoreSubscription] ⚠ Document does not exist yet (will be created)');
          existingDoc = null;
        } else {
          dev.log(
              '[FirestoreSubscription] ⚠ PlatformException getting existing doc: ${e.code} - ${e.message}, proceeding with save anyway');
          existingDoc = null;
        }
      } catch (e) {
        // Handle other errors
        dev.log(
            '[FirestoreSubscription] ⚠ Error getting existing doc: $e, proceeding with save anyway');
        existingDoc = null;
      }

      // Preserve createdAt if document already exists
      DateTime? createdAt;
      if (existingDoc?.exists == true) {
        try {
          final existing = PremiumSubscriptionModel.fromFirestore(existingDoc!);
          createdAt = existing.createdAt;
          dev.log('[FirestoreSubscription] Preserving createdAt: $createdAt');
        } catch (e) {
          dev.log('[FirestoreSubscription] ⚠ Error parsing existing doc: $e');
        }
      }

      dev.log('[FirestoreSubscription] Step 3: Preparing data to save...');
      final data = subscription
          .copyWith(
            createdAt: createdAt,
            lastSyncedAt: DateTime.now(),
          )
          .toFirestore();
      dev.log(
          '[FirestoreSubscription] Data prepared with ${data.length} fields');

      dev.log('[FirestoreSubscription] Step 4: Saving to Firestore...');
      // Use merge to avoid overwriting, and set persistence enabled
      await docRef.set(data, SetOptions(merge: true)).timeout(_timeoutDuration);

      dev.log(
          '[FirestoreSubscription] ✓ Successfully saved premium subscription to Firestore: isPremium=${subscription.isPremium}');
      dev.log(
          '[FirestoreSubscription] ===== SAVE PREMIUM SUBSCRIPTION SUCCESS =====');
    } on TimeoutException catch (e) {
      dev.log(
          '[FirestoreSubscription] ✗ Save operation timed out after ${_timeoutDuration.inSeconds}s: $e');
      dev.log(
          '[FirestoreSubscription] Note: Firestore offline persistence will retry when online');
      dev.log(
          '[FirestoreSubscription] ===== SAVE PREMIUM SUBSCRIPTION END (TIMEOUT) =====');
      // Firestore offline persistence will handle retry automatically
    } catch (e, stackTrace) {
      dev.log(
        '[FirestoreSubscription] ✗ CRITICAL ERROR saving premium subscription: $e',
        error: e,
        stackTrace: stackTrace,
      );
      dev.log(
          '[FirestoreSubscription] Note: This is a backup system, app will continue normally');
      dev.log(
          '[FirestoreSubscription] ===== SAVE PREMIUM SUBSCRIPTION END (ERROR) =====');
      // Don't throw - this is a backup system, shouldn't break the app
      // Firestore offline persistence will retry when connection is restored
    }
  }

  /// Update subscription status (useful for marking as expired)
  /// Non-blocking operation
  Future<void> updateSubscriptionStatus({
    required bool isPremium,
    DateTime? expirationDate,
  }) async {
    // Fire-and-forget
    unawaited(_updateSubscriptionStatusInternal(
      isPremium: isPremium,
      expirationDate: expirationDate,
    ));
  }

  /// Internal method to update subscription status
  Future<void> _updateSubscriptionStatusInternal({
    required bool isPremium,
    DateTime? expirationDate,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        dev.log('No user authenticated, cannot update subscription status');
        return;
      }

      final docRef = _getSubscriptionDoc();
      DocumentSnapshot<Map<String, dynamic>>? existingDoc;

      // Use serverAndCache which will try cache first, then server automatically
      try {
        existingDoc = await docRef
            .get(const GetOptions(source: Source.serverAndCache))
            .timeout(const Duration(seconds: 3));
        dev.log('Got existing doc for update: exists=${existingDoc.exists}');
      } on FirebaseException catch (e) {
        // Handle specific Firestore errors gracefully
        if (e.code == 'not-found') {
          dev.log('Document does not exist yet (will be created)');
          existingDoc = null;
        } else {
          dev.log(
              'Error getting existing doc for update: ${e.code} - ${e.message}');
          existingDoc = null;
        }
      } on PlatformException catch (e) {
        // Handle PlatformException which wraps Firebase errors
        final code = e.code.toString().toLowerCase();
        final message = e.message?.toString().toLowerCase() ?? '';
        if (code.contains('not-found') || message.contains('not found')) {
          dev.log('Document does not exist yet (will be created)');
          existingDoc = null;
        } else {
          dev.log(
              'PlatformException getting existing doc for update: ${e.code} - ${e.message}');
          existingDoc = null;
        }
      } catch (e) {
        // Handle other errors
        dev.log('Error getting existing doc for update: $e');
        existingDoc = null;
      }

      PremiumSubscriptionModel existing;
      if (existingDoc?.exists == true) {
        existing = PremiumSubscriptionModel.fromFirestore(existingDoc!);
      } else {
        existing = const PremiumSubscriptionModel(isPremium: false);
      }

      final updated = existing.copyWith(
        isPremium: isPremium,
        expirationDate: expirationDate ?? existing.expirationDate,
        lastSyncedAt: DateTime.now(),
      );

      await _savePremiumSubscriptionInternal(updated);
      dev.log('Updated subscription status in Firestore: isPremium=$isPremium');
    } catch (e, stackTrace) {
      dev.log(
        'Error updating subscription status in Firestore: $e',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Clear premium subscription (on logout or cancellation)
  /// Non-blocking operation
  Future<void> clearPremiumSubscription() async {
    // Fire-and-forget
    unawaited(_clearPremiumSubscriptionInternal());
  }

  /// Internal method to clear subscription
  Future<void> _clearPremiumSubscriptionInternal() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return;
      }

      await _getSubscriptionDoc().delete().timeout(_timeoutDuration);
      dev.log('Cleared premium subscription from Firestore');
    } on TimeoutException {
      dev.log('Firestore delete operation timed out');
    } catch (e, stackTrace) {
      dev.log(
        'Error clearing premium subscription from Firestore: $e',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Stream subscription changes (for real-time updates)
  /// Uses cache-first approach for offline support
  Stream<PremiumSubscriptionModel?> streamPremiumSubscription() {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Stream.value(null);
      }

      return _getSubscriptionDoc()
          .snapshots(includeMetadataChanges: true)
          .map((doc) {
        if (!doc.exists) {
          return null;
        }
        // Log if data is from cache
        if (doc.metadata.isFromCache) {
          dev.log('Subscription data from cache (offline mode)');
        }
        return PremiumSubscriptionModel.fromFirestore(doc);
      }).handleError((error) {
        dev.log('Error in subscription stream: $error');
        return null;
      });
    } catch (e) {
      dev.log('Error streaming premium subscription: $e');
      return Stream.value(null);
    }
  }
}
