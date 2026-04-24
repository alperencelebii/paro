import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing premium subscription data stored in Firestore
class PremiumSubscriptionModel {
  final bool isPremium;
  final String? planId; // e.g., 'pro', 'pas', 'monthly', 'yearly'
  final String? productIdentifier; // RevenueCat product identifier
  final DateTime? purchaseDate;
  final DateTime? expirationDate;
  final bool willRenew;
  final String? store; // 'APP_STORE', 'PLAY_STORE', etc.
  final DateTime? lastSyncedAt; // When this was last synced from RevenueCat
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PremiumSubscriptionModel({
    required this.isPremium,
    this.planId,
    this.productIdentifier,
    this.purchaseDate,
    this.expirationDate,
    this.willRenew = false,
    this.store,
    this.lastSyncedAt,
    this.createdAt,
    this.updatedAt,
  });

  /// Create from Firestore document
  factory PremiumSubscriptionModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) {
      return const PremiumSubscriptionModel(isPremium: false);
    }

    return PremiumSubscriptionModel(
      isPremium: data['isPremium'] as bool? ?? false,
      planId: data['planId'] as String?,
      productIdentifier: data['productIdentifier'] as String?,
      purchaseDate: (data['purchaseDate'] as Timestamp?)?.toDate(),
      expirationDate: (data['expirationDate'] as Timestamp?)?.toDate(),
      willRenew: data['willRenew'] as bool? ?? false,
      store: data['store'] as String?,
      lastSyncedAt: (data['lastSyncedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'isPremium': isPremium,
      if (planId != null) 'planId': planId,
      if (productIdentifier != null) 'productIdentifier': productIdentifier,
      if (purchaseDate != null) 'purchaseDate': Timestamp.fromDate(purchaseDate!),
      if (expirationDate != null)
        'expirationDate': Timestamp.fromDate(expirationDate!),
      'willRenew': willRenew,
      if (store != null) 'store': store,
      if (lastSyncedAt != null)
        'lastSyncedAt': Timestamp.fromDate(lastSyncedAt!),
      'updatedAt': FieldValue.serverTimestamp(),
      if (createdAt == null) 'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Check if subscription is currently active (not expired)
  bool get isActive {
    if (!isPremium) return false;
    if (expirationDate == null) return true; // Lifetime subscription
    return DateTime.now().isBefore(expirationDate!);
  }

  /// Create a copy with updated fields
  PremiumSubscriptionModel copyWith({
    bool? isPremium,
    String? planId,
    String? productIdentifier,
    DateTime? purchaseDate,
    DateTime? expirationDate,
    bool? willRenew,
    String? store,
    DateTime? lastSyncedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PremiumSubscriptionModel(
      isPremium: isPremium ?? this.isPremium,
      planId: planId ?? this.planId,
      productIdentifier: productIdentifier ?? this.productIdentifier,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expirationDate: expirationDate ?? this.expirationDate,
      willRenew: willRenew ?? this.willRenew,
      store: store ?? this.store,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

