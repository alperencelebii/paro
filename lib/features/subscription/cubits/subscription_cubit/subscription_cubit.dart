import 'dart:async';
import 'dart:developer';
import 'package:finance_track/features/subscription/services/subscription_service.dart';
import 'package:finance_track/core/services/auth_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'subscription_state.dart';

class SubscriptionCubit extends Cubit<SubscriptionState> {
  SubscriptionCubit() : super(const SubscriptionState());

  Future<bool> ensureProStatus({bool forceRefresh = false}) async {
    log('[SubscriptionCubit] ===== ENSURE PRO STATUS START =====');
    log('[SubscriptionCubit] forceRefresh: $forceRefresh, currentStatus: ${state.status}');
    
    // If force refresh is requested, always check again
    if (!forceRefresh && state.status == SubscriptionStatus.success) {
      log('[SubscriptionCubit] Using cached status: isProUser=${state.isProUser}');
      log('[SubscriptionCubit] ===== ENSURE PRO STATUS END (CACHED) =====');
      return state.isProUser;
    }
    
    log('[SubscriptionCubit] Step 1: Emitting loading state...');
    emit(state.copyWith(status: SubscriptionStatus.loading));
    
    try {
      // CRITICAL: Ensure user is identified in RevenueCat BEFORE checking subscription
      // This is essential for restoring purchases after re-login
      log('[SubscriptionCubit] Step 2: Ensuring RevenueCat user identification...');
      try {
        await AuthService.instance.ensureRevenueCatIdentification()
            .timeout(const Duration(seconds: 15), onTimeout: () {
          log('[SubscriptionCubit] ⚠ RevenueCat identification timed out, continuing anyway...');
          throw TimeoutException('RevenueCat identification timed out');
        });
        log('[SubscriptionCubit] ✓ RevenueCat identification complete');
      } on TimeoutException {
        log('[SubscriptionCubit] ⚠ RevenueCat identification timed out, continuing with subscription check...');
        // Continue anyway - might still work
      } catch (e, stackTrace) {
        log(
          '[SubscriptionCubit] ✗ Error during RevenueCat identification: $e',
          error: e,
          stackTrace: stackTrace,
        );
        log('[SubscriptionCubit] Continuing with subscription check anyway...');
        // Continue anyway - might still work
      }

      // Refresh customer info from RevenueCat if force refresh is requested
      if (forceRefresh) {
        log('[SubscriptionCubit] Step 3: Force refresh requested, refreshing customer info...');
        try {
          await SubscriptionService.refreshCustomerInfo()
              .timeout(const Duration(seconds: 10), onTimeout: () {
            log('[SubscriptionCubit] ⚠ Refresh customer info timed out, continuing...');
            return null;
          });
          log('[SubscriptionCubit] ✓ Customer info refreshed');
        } catch (e) {
          log('[SubscriptionCubit] ⚠ Error refreshing customer info: $e, continuing...');
          // Continue anyway
        }
      }

      log('[SubscriptionCubit] Step 4: Checking if user is pro...');
      final bool isPro = await SubscriptionService.isProUser()
          .timeout(const Duration(seconds: 15), onTimeout: () {
        log('[SubscriptionCubit] ✗ isProUser check timed out, assuming not premium');
        return false;
      });
      
      log('[SubscriptionCubit] ✓ Subscription check complete - Is Pro User: $isPro');
      log('[SubscriptionCubit] Step 5: Emitting success state...');
      
      emit(state.copyWith(
        isProUser: isPro,
        status: SubscriptionStatus.success,
      ));
      
      log('[SubscriptionCubit] ===== ENSURE PRO STATUS SUCCESS (isPro: $isPro) =====');
      return isPro;
    } on TimeoutException catch (e) {
      log('[SubscriptionCubit] ✗ Operation timed out: $e');
      log('[SubscriptionCubit] Emitting failure state...');
      emit(state.copyWith(status: SubscriptionStatus.failure));
      log('[SubscriptionCubit] ===== ENSURE PRO STATUS END (TIMEOUT) =====');
      return false;
    } catch (e, stackTrace) {
      log(
        '[SubscriptionCubit] ✗ CRITICAL ERROR checking pro user: $e',
        error: e,
        stackTrace: stackTrace,
      );
      log('[SubscriptionCubit] Emitting failure state...');
      emit(state.copyWith(status: SubscriptionStatus.failure));
      log('[SubscriptionCubit] ===== ENSURE PRO STATUS END (ERROR) =====');
      return false;
    }
  }

  Future<void> checkProStatus({bool forceRefresh = false}) async {
    await ensureProStatus(forceRefresh: forceRefresh);
  }
}
