import 'package:equatable/equatable.dart';
import '../../../../../core/models/currency_model.dart';

/// Base class for all currency events in the application.
///
/// All currency events must extend this class and implement [Equatable]
/// for proper event comparison.
abstract class CurrencyEvent extends Equatable {
  /// Creates a new [CurrencyEvent] instance
  const CurrencyEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load the saved currency from storage.
///
/// This event is typically dispatched when the application starts
/// or when the currency needs to be refreshed.
class LoadCurrency extends CurrencyEvent {
  /// Creates a new [LoadCurrency] instance
  const LoadCurrency();
}

/// Event to change the current currency.
///
/// This event is dispatched when the user selects a new currency
/// from the available options.
class ChangeCurrency extends CurrencyEvent {
  /// The new currency to be set
  final Currency currency;

  /// Creates a new [ChangeCurrency] instance
  const ChangeCurrency(this.currency);

  @override
  List<Object?> get props => [currency];
}
