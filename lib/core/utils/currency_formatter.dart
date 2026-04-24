import 'package:intl/intl.dart';
import '../models/currency_model.dart';

/// Utility class for formatting currency values
class CurrencyFormatter {
  /// Format a number as currency with the given currency
  static String format(double amount, Currency currency) {
    // Special case for INR which uses a different number format (lakhs, crores)
    if (currency.code == 'INR') {
      return _formatIndianCurrency(amount, currency.symbol);
    }

    // For other currencies, use the standard NumberFormat
    final formatter = NumberFormat.currency(
      symbol: currency.symbol,
      decimalDigits: 2,
    );

    return formatter.format(amount);
  }

  /// Format a number as Indian currency (with lakhs and crores)
  static String _formatIndianCurrency(double amount, String symbol) {
    // Format with commas for Indian numbering system (lakhs, crores)
    final formatter = NumberFormat('#,##,##0.00');
    return '$symbol ${formatter.format(amount)}';
  }

  /// Format a number as currency with the given currency without decimal places
  static String formatCompact(double amount, Currency currency) {
    if (amount >= 1000000) {
      return '${currency.symbol} ${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${currency.symbol} ${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return '${currency.symbol} ${amount.toStringAsFixed(0)}';
    }
  }
}
