/// Model representing detailed subscription information
class SubscriptionDetails {
  final SubscriptionInfo primarySubscription;
  final List<SubscriptionInfo> allActiveSubscriptions;
  final List<TransactionInfo> allTransactions;
  final String originalAppUserId;
  final DateTime firstSeen;
  final DateTime requestDate;
  final String? managementURL;

  SubscriptionDetails({
    required this.primarySubscription,
    required this.allActiveSubscriptions,
    required this.allTransactions,
    required this.originalAppUserId,
    required this.firstSeen,
    required this.requestDate,
    this.managementURL,
  });
}

/// Model representing subscription information
class SubscriptionInfo {
  final String identifier;
  final String productIdentifier;
  final DateTime? purchaseDate;
  final DateTime? expirationDate;
  final bool isActive;
  final bool willRenew;
  final String periodType; // 'NORMAL', 'INTRO', 'TRIAL'
  final String store; // 'APP_STORE', 'PLAY_STORE', 'STRIPE', etc.
  final bool isSandbox;

  SubscriptionInfo({
    required this.identifier,
    required this.productIdentifier,
    this.purchaseDate,
    this.expirationDate,
    required this.isActive,
    required this.willRenew,
    required this.periodType,
    required this.store,
    required this.isSandbox,
  });
}

/// Model representing transaction information
class TransactionInfo {
  final String productIdentifier;
  final DateTime purchaseDate;
  final String transactionIdentifier;

  TransactionInfo({
    required this.productIdentifier,
    required this.purchaseDate,
    required this.transactionIdentifier,
  });
}

