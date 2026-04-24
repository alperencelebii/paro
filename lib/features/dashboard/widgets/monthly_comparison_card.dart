import 'package:finance_track/core/models/currency_model.dart';
import 'package:finance_track/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Widget for displaying monthly comparison
class MonthlyComparisonCard extends StatelessWidget {
  final double thisMonthIncome;
  final double thisMonthExpense;
  final double thisMonthBalance;
  final Currency currency;

  const MonthlyComparisonCard({
    super.key,
    required this.thisMonthIncome,
    required this.thisMonthExpense,
    required this.thisMonthBalance,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(
      symbol: currency.symbol,
      decimalDigits: 2,
    );

    // Current month name
    final currentMonth = DateFormat('MMMM').format(DateTime.now());

    return GestureDetector(
      onTap: () {
        // Navigate to monthly summary screen
        context.pushNamed(AppRoutes.monthlySummary);
      },
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(0, 4),
              blurRadius: 12,
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 20.r,
              right: 20.r,
              child: Icon(
                Icons.arrow_forward_ios,
                size: 16.r,
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$currentMonth Summary',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Monthly statistics
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          context,
                          'Income',
                          thisMonthIncome,
                          formatter,
                          Colors.greenAccent.shade700,
                          Icons.arrow_upward_rounded,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: _buildStatItem(
                          context,
                          'Expense',
                          thisMonthExpense,
                          formatter,
                          Colors.redAccent,
                          Icons.arrow_downward_rounded,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: _buildStatItem(
                          context,
                          'Balance',
                          thisMonthBalance,
                          formatter,
                          thisMonthBalance >= 0
                              ? Colors.blueAccent
                              : Colors.orangeAccent,
                          thisMonthBalance >= 0
                              ? Icons.account_balance_wallet
                              : Icons.account_balance_wallet,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  // Progress bar showing expense to income ratio
                  if (thisMonthIncome > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Expense to Income Ratio',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${((thisMonthExpense / thisMonthIncome) * 100).toStringAsFixed(1)}%',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: thisMonthExpense > thisMonthIncome
                                ? Colors.redAccent
                                : Colors.greenAccent.shade700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4.r),
                      child: LinearProgressIndicator(
                        value: thisMonthIncome > 0
                            ? (thisMonthExpense / thisMonthIncome)
                                .clamp(0.0, 1.0)
                            : 0,
                        backgroundColor: Colors.grey.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          thisMonthExpense > thisMonthIncome
                              ? Colors.redAccent
                              : Colors.greenAccent.shade700,
                        ),
                        minHeight: 8.h,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '0%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ),
                        Text(
                          '50%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ),
                        Text(
                          '100%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String title,
    double amount,
    NumberFormat formatter,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 14.r,
              ),
              SizedBox(width: 4.w),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            formatter.format(amount),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
