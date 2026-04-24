import 'dart:developer' as dev;
import 'package:purchases_flutter/purchases_flutter.dart';
import '../models/subscription_details_model.dart';
import '../services/subscription_service.dart';

/// Repository for managing subscription details and information
/// Provides detailed subscription data from RevenueCat
class SubscriptionManagementRepository {
  /// Get detailed subscription information for the current user
  Future<SubscriptionDetails?> getSubscriptionDetails() async {
    try {
      // Check if RevenueCat is configured
      if (!SubscriptionService.isConfigured) {
        dev.log('Error: RevenueCat is not configured. Cannot get subscription details.');
        return null;
      }
      
      final customerInfo = await Purchases.getCustomerInfo();

      // Check for both 'pas' and 'pro' entitlements
      final activeEntitlements = customerInfo.entitlements.active;
      final pasEntitlement = activeEntitlements['pas'];
      final proEntitlement = activeEntitlements['pro'];

      // Prefer 'pas' over 'pro' if both exist
      final activeEntitlement = pasEntitlement ?? proEntitlement;

      if (activeEntitlement == null) {
        dev.log('No active subscription found');
        return null;
      }

      final productIdentifier = activeEntitlement.productIdentifier;
      final purchaseDate = activeEntitlement.latestPurchaseDate;
      final expirationDate = activeEntitlement.expirationDate;
      final isActive = activeEntitlement.isActive;
      final willRenew = activeEntitlement.willRenew;
      final periodType = activeEntitlement.periodType;
      final store = activeEntitlement.store;
      final entitlementIdentifier = activeEntitlement.identifier;

      // Get all active subscriptions for detailed view
      final allActiveSubscriptions = <SubscriptionInfo>[];

      for (final entitlement in activeEntitlements.values) {
        if (entitlement.isActive) {
          allActiveSubscriptions.add(
            SubscriptionInfo(
              identifier: entitlement.identifier,
              productIdentifier: entitlement.productIdentifier,
              purchaseDate: entitlement.latestPurchaseDate as DateTime?,
              expirationDate: entitlement.expirationDate as DateTime?,
              isActive: entitlement.isActive,
              willRenew: entitlement.willRenew,
              periodType: entitlement.periodType.name,
              store: entitlement.store.name,
              isSandbox: entitlement.isSandbox,
            ),
          );
        }
      }

      // Get all transactions
      final allTransactions = <TransactionInfo>[];
      for (final transaction in customerInfo.nonSubscriptionTransactions) {
        allTransactions.add(
          TransactionInfo(
            productIdentifier: transaction.productIdentifier,
            purchaseDate: transaction.purchaseDate as DateTime,
            transactionIdentifier: transaction.transactionIdentifier,
          ),
        );
      }

      return SubscriptionDetails(
        primarySubscription: SubscriptionInfo(
          identifier: entitlementIdentifier,
          productIdentifier: productIdentifier,
          purchaseDate: purchaseDate as DateTime?,
          expirationDate: expirationDate as DateTime?,
          isActive: isActive,
          willRenew: willRenew,
          periodType: periodType.name,
          store: store.name,
          isSandbox: activeEntitlement.isSandbox,
        ),
        allActiveSubscriptions: allActiveSubscriptions,
        allTransactions: allTransactions,
        originalAppUserId: customerInfo.originalAppUserId,
        firstSeen: customerInfo.firstSeen as DateTime,
        requestDate: customerInfo.requestDate as DateTime,
        managementURL: customerInfo.managementURL,
      );
    } catch (e, stackTrace) {
      dev.log(
        'Error fetching subscription details: $e',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Check if user has active 'pas' subscription
  Future<bool> hasActivePasSubscription() async {
    if (!SubscriptionService.isConfigured) {
      dev.log('Error: RevenueCat is not configured. Cannot check pas subscription.');
      return false;
    }
    
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.active.containsKey('pas');
    } catch (e) {
      dev.log('Error checking pas subscription: $e');
      return false;
    }
  }

  /// Check if user has any active subscription (pas or pro)
  Future<bool> hasActiveSubscription() async {
    if (!SubscriptionService.isConfigured) {
      dev.log('Error: RevenueCat is not configured. Cannot check active subscription.');
      return false;
    }
    
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final activeEntitlements = customerInfo.entitlements.active;
      return activeEntitlements.containsKey('pas') ||
          activeEntitlements.containsKey('pro');
    } catch (e) {
      dev.log('Error checking active subscription: $e');
      return false;
    }
  }

  /// Refresh customer info from RevenueCat
  Future<void> refreshCustomerInfo() async {
    if (!SubscriptionService.isConfigured) {
      dev.log('Error: RevenueCat is not configured. Cannot refresh customer info.');
      return;
    }
    
    try {
      await Purchases.getCustomerInfo();
      dev.log('Customer info refreshed successfully');
    } catch (e) {
      dev.log('Error refreshing customer info: $e');
      rethrow;
    }
  }
}
