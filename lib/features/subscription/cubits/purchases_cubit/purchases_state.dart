// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'purchases_cubit.dart';

enum OfferingStatus { initial, loading, success, failure }

enum PurchasesStatus { initial, loading, success, failure }

class PurchasesState extends Equatable {
  const PurchasesState({
    this.offeringStatus = OfferingStatus.initial,
    this.purchasesStatus = PurchasesStatus.initial,
    this.packages = const [],
    this.errorMesssage = '',
    this.offerings,
  });
  final OfferingStatus offeringStatus;
  final PurchasesStatus purchasesStatus;
  final List<Package> packages;
  final String errorMesssage;
  final Offering? offerings;
  @override
  List<Object?> get props =>
      [offeringStatus, purchasesStatus, packages, errorMesssage, offerings];

  PurchasesState copyWith({
    OfferingStatus? offeringStatus,
    PurchasesStatus? purchasesStatus,
    List<Package>? packages,
    String? errorMesssage,
    Offering? offerings,
  }) {
    return PurchasesState(
      offeringStatus: offeringStatus ?? this.offeringStatus,
      purchasesStatus: purchasesStatus ?? this.purchasesStatus,
      packages: packages ?? this.packages,
      errorMesssage: errorMesssage ?? this.errorMesssage,
      offerings: offerings ?? this.offerings,
    );
  }
}
