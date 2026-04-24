part of 'subscription_management_bloc.dart';

/// Status of subscription management
enum SubscriptionManagementStatus {
  initial,
  loading,
  loaded,
  error,
  noSubscription,
}

/// State for subscription management
class SubscriptionManagementState extends Equatable {
  final SubscriptionManagementStatus status;
  final SubscriptionDetails? subscriptionDetails;
  final String? errorMessage;
  final bool isRefreshing;
  final bool hasActiveSubscription;
  final bool hasPasSubscription;

  const SubscriptionManagementState({
    this.status = SubscriptionManagementStatus.initial,
    this.subscriptionDetails,
    this.errorMessage,
    this.isRefreshing = false,
    this.hasActiveSubscription = false,
    this.hasPasSubscription = false,
  });

  SubscriptionManagementState copyWith({
    SubscriptionManagementStatus? status,
    SubscriptionDetails? subscriptionDetails,
    String? errorMessage,
    bool? isRefreshing,
    bool? hasActiveSubscription,
    bool? hasPasSubscription,
  }) {
    return SubscriptionManagementState(
      status: status ?? this.status,
      subscriptionDetails: subscriptionDetails ?? this.subscriptionDetails,
      errorMessage: errorMessage ?? this.errorMessage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      hasActiveSubscription: hasActiveSubscription ?? this.hasActiveSubscription,
      hasPasSubscription: hasPasSubscription ?? this.hasPasSubscription,
    );
  }

  @override
  List<Object?> get props => [
        status,
        subscriptionDetails,
        errorMessage,
        isRefreshing,
        hasActiveSubscription,
        hasPasSubscription,
      ];
}

