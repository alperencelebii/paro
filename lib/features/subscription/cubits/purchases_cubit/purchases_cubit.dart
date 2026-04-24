import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:finance_track/features/subscription/services/subscription_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

part 'purchases_state.dart';

class PurchasesCubit extends Cubit<PurchasesState> {
  PurchasesCubit() : super(const PurchasesState());
  List<Package> _packages = [];

  Future<void> loadOfferings({bool autoPresentPaywall = true}) async {
    emit(state.copyWith(
      offeringStatus: OfferingStatus.loading,
      errorMesssage: '',
    ));
    
    // Check if RevenueCat is configured
    if (!SubscriptionService.isConfigured) {
      log('Error: RevenueCat is not configured. Cannot load offerings.');
      emit(state.copyWith(
        offeringStatus: OfferingStatus.failure,
        errorMesssage: 'RevenueCat is not configured. Please check your API key.',
      ));
      return;
    }
    
    try {
      final Offerings? offerings = await SubscriptionService.fetchOffering();

      if (offerings != null) {
        _packages = [];
        final allOfferings = offerings.all.values.toList();
        for (final offering in allOfferings) {
          if (offering.monthly != null) {
            _packages.add(offering.monthly!);
          }
          if (offering.annual != null) {
            _packages.add(offering.annual!);
          }
          if (offering.lifetime != null) {
            _packages.add(offering.lifetime!);
          }
        }
        final Offering? offering = offerings.getOffering('pro') ??
            offerings.current ??
            (allOfferings.isNotEmpty ? allOfferings.first : null);
        if (offering != null) {
          emit(state.copyWith(
            packages: _packages,
            offeringStatus: OfferingStatus.success,
            offerings: offering,
          ));
          if (autoPresentPaywall) {
            await RevenueCatUI.presentPaywall(offering: offering);
          }
        } else {
          emit(state.copyWith(
            packages: [],
            offeringStatus: OfferingStatus.failure,
            errorMesssage:
                'No plans are available right now. Please try again later.',
          ));
        }
      } else {
        emit(state.copyWith(
          packages: [],
          offeringStatus: OfferingStatus.failure,
          errorMesssage: 'Unable to fetch plans. No offerings returned.',
        ));
      }
    } catch (e) {
      log('Error Fetching Offering Cubit : $e');
      emit(state.copyWith(
          offeringStatus: OfferingStatus.failure,
          packages: [],
          errorMesssage: e.toString()));
    }
  }

  Future<void> loadPackages(
      {required Package package, required Function onSuccess}) async {
    emit(state.copyWith(purchasesStatus: PurchasesStatus.loading));
    
    // Check if RevenueCat is configured
    if (!SubscriptionService.isConfigured) {
      log('Error: RevenueCat is not configured. Cannot purchase package.');
      emit(state.copyWith(
        purchasesStatus: PurchasesStatus.failure,
        errorMesssage: 'RevenueCat is not configured. Please check your API key.',
      ));
      return;
    }
    
    try {
      // CRITICAL: Ensure user is identified in RevenueCat BEFORE purchase
      // This ensures the purchase is linked to their Firebase UID
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        log('Ensuring user is identified in RevenueCat before purchase...');
        await SubscriptionService.identifyUser(user.uid);
        log('User identified, proceeding with purchase...');
      }
      
      // Actually purchase the package
      final purchaserInfo = await Purchases.purchasePackage(package);
      
      log('Purchase completed. Customer info: ${purchaserInfo.customerInfo.originalAppUserId}');
      log('Active entitlements after purchase: ${purchaserInfo.customerInfo.entitlements.active.keys.toList()}');
      
      final hasActiveSubscription = purchaserInfo.customerInfo.entitlements.active.containsKey('pro') ||
                                    purchaserInfo.customerInfo.entitlements.active.containsKey('pas');
      
      if (hasActiveSubscription) {
        log('Purchase successful! User now has active subscription.');
        
        // Sync subscription to Firestore after successful purchase
        // This ensures premium status is persisted even if RevenueCat fails later
        try {
          await SubscriptionService.refreshCustomerInfo();
          log('✓ Subscription synced to Firestore after purchase');
        } catch (e) {
          log('⚠ Error syncing subscription to Firestore after purchase: $e');
          // Don't fail the purchase if Firestore sync fails
        }
        
        emit(state.copyWith(
          purchasesStatus: PurchasesStatus.success,
          packages: _packages,
        ));
        onSuccess();
      } else {
        log('Purchase completed but no active subscription found');
        emit(state.copyWith(
          packages: _packages,
          errorMesssage: 'Purchase completed but subscription not active',
        ));
      }
    } on PlatformException catch (e) {
      if (e.code == PurchasesErrorCode.purchaseCancelledError.name) {
        log('Customer Purchase Cancelled');
        emit(state.copyWith(
            packages: _packages,
            purchasesStatus: PurchasesStatus.failure,
            errorMesssage: 'Purchase was cancelled'));
      } else {
        log('Error Purchasing Package: $e');
        emit(state.copyWith(
          packages: _packages,
          purchasesStatus: PurchasesStatus.failure,
          errorMesssage: e.message ?? 'Purchase failed'));
      }
    } catch (e) {
      log('Error Purchasing Package: $e');
      emit(state.copyWith(
        packages: _packages,
        purchasesStatus: PurchasesStatus.failure,
        errorMesssage: e.toString()));
    }
  }

  Future<void> showPaywall() async {
    final offering = state.offerings;
    if (offering == null) {
      await loadOfferings();
      return;
    }
    try {
      await RevenueCatUI.presentPaywall(offering: offering);
    } catch (e) {
      log('Error presenting paywall : $e');
      emit(state.copyWith(
          errorMesssage: 'Unable to open paywall. Please try again.'));
    }
  }
}
