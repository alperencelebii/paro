import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:finance_track/features/profile/currency/bloc/currency/currency_bloc.dart';
import 'package:finance_track/features/profile/currency/bloc/currency/currency_state.dart';
import 'package:finance_track/core/models/currency_model.dart';

extension CurrencyContextExtension on BuildContext {
  /// Gets the currently selected currency from the CurrencyBloc
  Currency get selectedCurrency {
    final state = read<CurrencyBloc>().state;
    return state is CurrencyLoaded ? state.selectedCurrency : Currencies.inr;
  }

  /// Gets the currency symbol from the currently selected currency
  String get currencySymbol => selectedCurrency.symbol;

  /// Gets the currency code from the currently selected currency
  String get currencyCode => selectedCurrency.code;
}
