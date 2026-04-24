part of 'subscription_management_bloc.dart';

/// Base class for subscription management events
abstract class SubscriptionManagementEvent extends Equatable {
  const SubscriptionManagementEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load subscription details
class LoadSubscriptionDetails extends SubscriptionManagementEvent {
  const LoadSubscriptionDetails();
}

/// Event to refresh subscription details
class RefreshSubscriptionDetails extends SubscriptionManagementEvent {
  const RefreshSubscriptionDetails();
}

/// Event to check if user has active subscription
class CheckActiveSubscription extends SubscriptionManagementEvent {
  const CheckActiveSubscription();
}

/// Event to test subscription restoration
class TestSubscriptionRestore extends SubscriptionManagementEvent {
  final String userId;
  const TestSubscriptionRestore(this.userId);
}

