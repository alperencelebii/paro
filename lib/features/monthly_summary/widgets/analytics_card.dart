import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../profile/currency/bloc/currency/currency_bloc.dart';
import '../../profile/currency/bloc/currency/currency_state.dart';
import '../../../core/models/currency_model.dart';
import 'package:finance_track/core/localization/localization.dart';

class AnalyticsCard extends StatelessWidget {
  final double totalIncome;
  final double totalExpenses;
  final double balance;

  const AnalyticsCard({
    super.key,
    required this.totalIncome,
    required this.totalExpenses,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<CurrencyBloc, CurrencyState>(
      builder: (context, state) {
        final currency =
            state is CurrencyLoaded ? state.selectedCurrency : Currencies.inr;

        final currencyFormat = NumberFormat.currency(
          symbol: currency.symbol,
          decimalDigits: 2,
        );

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                offset: const Offset(0, 4),
                blurRadius: 20,
              ),
            ],
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.analytics_outlined,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    LocalizedText('Monthly Analytics',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Analytics Items
                IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildAnalyticsItem(
                          context,
                          'Income',
                          totalIncome,
                          Icons.arrow_upward_rounded,
                          Colors.green.shade600,
                          currencyFormat,
                        ),
                      ),
                      VerticalDivider(
                        width: 24,
                        thickness: 1,
                        color: theme.dividerColor.withValues(alpha: 0.2),
                      ),
                      Expanded(
                        child: _buildAnalyticsItem(
                          context,
                          'Expenses',
                          totalExpenses,
                          Icons.arrow_downward_rounded,
                          Colors.red.shade600,
                          currencyFormat,
                        ),
                      ),
                      VerticalDivider(
                        width: 24,
                        thickness: 1,
                        color: theme.dividerColor.withValues(alpha: 0.2),
                      ),
                      Expanded(
                        child: _buildAnalyticsItem(
                          context,
                          'Balance',
                          balance,
                          balance >= 0
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          balance >= 0
                              ? Colors.green.shade600
                              : Colors.red.shade600,
                          currencyFormat,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Enhanced Insights Section
                if (totalIncome > 0 || totalExpenses > 0) ...[
                  LocalizedText('Key Insights',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInsightCard(
                    context,
                    isPositive: balance >= 0,
                    insights:
                        _generateInsights(totalIncome, totalExpenses, balance),
                    currencyFormat: currencyFormat,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  List<InsightItem> _generateInsights(
    double income,
    double expenses,
    double balance,
  ) {
    final insights = <InsightItem>[];

    if (income > 0) {
      // Savings Rate
      final savingsRate = (balance / income * 100).abs();
      if (balance >= 0) {
        insights.add(
          InsightItem(
            icon: Icons.savings_rounded,
            color: Colors.green.shade600,
            title: 'Savings Rate',
            description:
                'You\'re saving ${savingsRate.toStringAsFixed(1)}% of your income',
          ),
        );
      } else {
        insights.add(
          InsightItem(
            icon: Icons.warning_rounded,
            color: Colors.red.shade600,
            title: 'Overspending Alert',
            description:
                'You\'re spending ${savingsRate.toStringAsFixed(1)}% more than your income',
          ),
        );
      }

      // Expense to Income Ratio
      final expenseRatio = (expenses / income * 100);
      insights.add(
        InsightItem(
          icon: Icons.account_balance_wallet_rounded,
          color: expenseRatio <= 70
              ? Colors.green.shade600
              : Colors.orange.shade600,
          title: 'Expense Ratio',
          description:
              'Your expenses are ${expenseRatio.toStringAsFixed(1)}% of your income',
        ),
      );
    }

    // Daily Average
    if (expenses > 0) {
      final dailyAverage = expenses / 30;
      insights.add(
        InsightItem(
          icon: Icons.calendar_today_rounded,
          color: Colors.blue.shade600,
          title: 'Daily Average',
          description:
              'You spend about ${NumberFormat.currency(symbol: '').format(dailyAverage)} per day',
        ),
      );
    }

    return insights;
  }

  Widget _buildInsightCard(
    BuildContext context, {
    required bool isPositive,
    required List<InsightItem> insights,
    required NumberFormat currencyFormat,
  }) {
    final theme = Theme.of(context);

    return Column(
      children: [
        for (var i = 0; i < insights.length; i++) ...[
          _buildInsightItem(context, insights[i]),
          if (i < insights.length - 1)
            Divider(
              height: 1,
              thickness: 1,
              color: theme.dividerColor.withValues(alpha: 0.1),
            ),
        ],
      ],
    );
  }

  Widget _buildInsightItem(BuildContext context, InsightItem insight) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: insight.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              insight.icon,
              color: insight.color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LocalizedText(
                  insight.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                LocalizedText(
                  insight.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color
                        ?.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsItem(
    BuildContext context,
    String label,
    double amount,
    IconData icon,
    Color color,
    NumberFormat currencyFormat,
  ) {
    final theme = Theme.of(context);
    final formattedAmount = currencyFormat.format(amount.abs());

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 4),
              LocalizedText(
                formattedAmount,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        LocalizedText(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class InsightItem {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const InsightItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });
}
