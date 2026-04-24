import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/services/currency_service.dart';
import 'currency_event.dart';
import 'currency_state.dart';

/// BLoC for managing currency state in the application.
///
/// This bloc handles:
/// - Loading the saved currency from storage
/// - Changing the current currency
/// - Managing currency state transitions
class CurrencyBloc extends Bloc<CurrencyEvent, CurrencyState> {
  /// The service responsible for currency operations
  final CurrencyService _currencyService;

  /// Whether to enable debug prints for development
  static const bool enableDebugPrints = false;

  /// Creates a new [CurrencyBloc] instance
  CurrencyBloc({
    required CurrencyService currencyService,
  })  : _currencyService = currencyService,
        super(const CurrencyInitial()) {
    on<LoadCurrency>(_onLoadCurrency);
    on<ChangeCurrency>(_onChangeCurrency);
  }

  @override
  void onEvent(CurrencyEvent event) {
    super.onEvent(event);
    if (enableDebugPrints) {
      debugPrint('CurrencyBloc event: $event');
    }
  }

  @override
  void onTransition(Transition<CurrencyEvent, CurrencyState> transition) {
    super.onTransition(transition);
    if (enableDebugPrints) {
      debugPrint('CurrencyBloc transition: $transition');
    }
  }

  /// Handles the [LoadCurrency] event by loading the saved currency from storage
  Future<void> _onLoadCurrency(
    LoadCurrency event,
    Emitter<CurrencyState> emit,
  ) async {
    try {
      emit(const CurrencyLoading());

      final currency = await _currencyService.getSavedCurrency();

      emit(CurrencyLoaded(selectedCurrency: currency));
    } catch (e, stackTrace) {
      debugPrint('Error loading currency: $e\n$stackTrace');
      emit(CurrencyError('Failed to load currency: ${e.toString()}'));
    }
  }

  /// Handles the [ChangeCurrency] event by saving the new currency to storage
  Future<void> _onChangeCurrency(
    ChangeCurrency event,
    Emitter<CurrencyState> emit,
  ) async {
    try {
      if (state is! CurrencyLoaded) {
        emit(const CurrencyError('Invalid state for currency change'));
        return;
      }

      final success = await _currencyService.saveCurrency(event.currency);
      if (!success) {
        emit(const CurrencyError('Failed to save currency'));
        return;
      }

      emit(CurrencyLoaded(selectedCurrency: event.currency));
    } catch (e, stackTrace) {
      debugPrint('Error changing currency: $e\n$stackTrace');
      emit(CurrencyError('Failed to change currency: ${e.toString()}'));
    }
  }
}
