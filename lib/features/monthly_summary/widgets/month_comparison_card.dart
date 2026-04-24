import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../profile/currency/bloc/currency/currency_bloc.dart';
import '../../profile/currency/bloc/currency/currency_state.dart';
import '../../../core/models/currency_model.dart';
import 'package:intl/intl.dart';

class MonthComparisonCard extends StatelessWidget {
  final Map<String, double> monthComparison;

  const MonthComparisonCard({
    super.key,
    required this.monthComparison,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (monthComparison.isEmpty) {
      return _buildEmptyState(context);
    }

    final currentAmount = monthComparison['current'] ?? 0.0;
    final previousAmount = monthComparison['previous'] ?? 0.0;
    final difference = currentAmount - previousAmount;
    final percentageChange = previousAmount != 0
        ? ((currentAmount - previousAmount) / previousAmount * 100)
        : 0.0;
    final isIncrease = difference > 0;

    return BlocBuilder<CurrencyBloc, CurrencyState>(
      builder: (context, state) {
        final currency =
            state is CurrencyLoaded ? state.selectedCurrency : Currencies.inr;
        final currencyFormat = NumberFormat.currency(
          symbol: currency.symbol,
          decimalDigits: 0,
        );

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                offset: const Offset(0, 4),
                blurRadius: 20,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.compare_arrows_rounded,
                        color: theme.colorScheme.secondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Month-over-Month',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Comparison Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildAmountCard(
                        theme,
                        'Current Month',
                        currencyFormat.format(currentAmount),
                        Icons.calendar_today_rounded,
                        theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildAmountCard(
                        theme,
                        'Previous Month',
                        currencyFormat.format(previousAmount),
                        Icons.calendar_month_rounded,
                        theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Change Indicator
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (isIncrease ? Colors.red : Colors.green)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isIncrease ? Colors.red : Colors.green)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isIncrease
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          color: isIncrease ? Colors.red : Colors.green,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isIncrease
                                  ? 'Spending Increased'
                                  : 'Spending Decreased',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: isIncrease ? Colors.red : Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${isIncrease ? '+' : '-'}${currencyFormat.format(difference.abs())} (${percentageChange.abs().toStringAsFixed(1)}%)',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: (isIncrease ? Colors.red : Colors.green)
                                    .withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isIncrease
                            ? Icons.warning_rounded
                            : Icons.check_circle_rounded,
                        color: isIncrease ? Colors.red : Colors.green,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAmountCard(
    ThemeData theme,
    String label,
    String amount,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: color.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color:
                      theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              amount,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, 4),
            blurRadius: 20,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.compare_arrows_rounded,
              size: 48,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No comparison data available',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add more transactions to see spending comparisons',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
