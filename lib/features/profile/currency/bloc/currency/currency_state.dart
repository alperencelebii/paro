import 'package:equatable/equatable.dart';
import '../../../../../core/models/currency_model.dart';

/// Base class for all currency states in the application.
///
/// All currency states must extend this class and implement [Equatable]
/// for proper state comparison.
abstract class CurrencyState extends Equatable {
  /// Creates a new [CurrencyState] instance
  const CurrencyState();

  @override
  List<Object?> get props => [];
}

/// Initial state of the currency bloc.
///
/// This state is used when the bloc is first created and before any
/// currency data has been loaded.
class CurrencyInitial extends CurrencyState {
  /// Creates a new [CurrencyInitial] instance
  const CurrencyInitial();
}

/// Loading state of the currency bloc.
///
/// This state is used when the bloc is loading currency data from storage.
class CurrencyLoading extends CurrencyState {
  /// Creates a new [CurrencyLoading] instance
  const CurrencyLoading();
}

/// Error state of the currency bloc.
///
/// This state is used when an error occurs during currency operations.
class CurrencyError extends CurrencyState {
  /// The error message describing what went wrong
  final String message;

  /// Creates a new [CurrencyError] instance
  const CurrencyError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Loaded state of the currency bloc.
///
/// This state is used when currency data has been successfully loaded
/// from storage.
class CurrencyLoaded extends CurrencyState {
  /// The currently selected currency
  final Currency selectedCurrency;

  /// Creates a new [CurrencyLoaded] instance
  const CurrencyLoaded({
    required this.selectedCurrency,
  });

  /// Getter for currency (for backward compatibility)
  Currency get currency => selectedCurrency;

  @override
  List<Object?> get props => [selectedCurrency];

  /// Creates a copy of this state with the provided values
  CurrencyLoaded copyWith({
    Currency? selectedCurrency,
  }) {
    return CurrencyLoaded(
      selectedCurrency: selectedCurrency ?? this.selectedCurrency,
    );
  }
}
