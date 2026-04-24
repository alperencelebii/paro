// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'subscription_cubit.dart';

enum SubscriptionStatus { initial, loading, success, failure }

class SubscriptionState extends Equatable {
  const SubscriptionState({
     this.status=SubscriptionStatus.initial,
    this.isProUser = false,
  });
  final SubscriptionStatus status;
  final bool isProUser;
  @override
  List<Object> get props => [isProUser,status];

  SubscriptionState copyWith({
    SubscriptionStatus? status,
    bool? isProUser,
  }) {
    return SubscriptionState(
      status: status ?? this.status,
      isProUser: isProUser ?? this.isProUser,
    );
  }
}
