import 'package:finance_track/features/budget/screens/budget_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

import '../../../core/models/currency_model.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/budget_model.dart';
import '../bloc/budget_bloc/budget_bloc.dart';

class BudgetCard extends StatelessWidget {
  final Currency currency;
  final VoidCallback? onTap;

  const BudgetCard({
    super.key,
    required this.currency,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(
      symbol: currency.symbol,
      decimalDigits: 0,
    );

    return BlocBuilder<BudgetBloc, BudgetState>(
      builder: (context, state) {
        if (state is BudgetLoaded && state.activeBudget != null) {
          final budget = state.activeBudget!;
          final spent = state.spent;
          final remaining = state.remaining;
          final daysRemaining = state.daysRemaining;
          final dailyBudget = state.dailyBudget;
          final percentUsed = state.percentUsed;

          // Different colors based on budget usage
          final progressColor = percentUsed < 0.7
              ? const Color(0xFF4CAF50) // Green
              : percentUsed < 0.9
                  ? const Color(0xFFFFA726) // Orange
                  : const Color(0xFFF44336); // Red

          return Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                ),
              ],
              color: theme.cardTheme.color ?? Colors.white,
            ),
            child: Column(
              children: [
                // Header section with colored gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.8),
                        theme.colorScheme.primary,
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24.r),
                      topRight: Radius.circular(24.r),
                    ),
                  ),
                  padding: EdgeInsets.all(12.r),
                  child: Column(
                    children: [
                      // Budget title and days remaining
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8.r),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getBudgetIcon(budget.period),
                                  color: Colors.white,
                                  size: 18.r,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${budget.period.displayName} Budget',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    '$daysRemaining days remaining',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color:
                                          Colors.white.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // Percentage indicator pill
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: percentUsed < 0.7
                                  ? Colors.green.withValues(alpha: 0.2)
                                  : percentUsed < 0.9
                                      ? Colors.orange.withValues(alpha: 0.2)
                                      : Colors.red.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Text(
                              '${(percentUsed * 100).toInt()}% Used',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: percentUsed < 0.7
                                    ? Colors.green[100]
                                    : percentUsed < 0.9
                                        ? Colors.orange[100]
                                        : Colors.red[100],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 24.h),

                      // Budget amounts
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildAmountColumn(
                            context,
                            title: 'Total',
                            amount: formatter.format(budget.amount),
                            icon: Icons.account_balance_wallet_outlined,
                            iconColor: Colors.white,
                          ),
                          _buildAmountColumn(
                            context,
                            title: 'Spent',
                            amount: formatter.format(spent),
                            icon: Icons.arrow_downward_rounded,
                            iconColor: Colors.white,
                          ),
                          _buildAmountColumn(
                            context,
                            title: 'Remaining',
                            amount: formatter.format(remaining),
                            icon: Icons.savings_outlined,
                            iconColor: Colors.white,
                            isHighlighted: true,
                          ),
                        ],
                      ),

                      SizedBox(height: 24.h),

                      // Linear progress indicator
                      LinearPercentIndicator(
                        lineHeight: 10.h,
                        percent: percentUsed,
                        animation: true,
                        animationDuration: 1000,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        progressColor: progressColor,
                        barRadius: Radius.circular(5.r),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),

                // Daily budget info
                Padding(
                  padding: EdgeInsets.all(12.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Budget',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // Daily budget card
                      Container(
                        padding: EdgeInsets.all(16.r),
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Daily budget amount circle
                            Container(
                              width: 56.r,
                              height: 56.r,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.paid_outlined,
                                  color: theme.colorScheme.primary,
                                  size: 24.r,
                                ),
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    formatter.format(dailyBudget),
                                    style:
                                        theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    'Available to spend today',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24.h),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                // Navigate to budget form for editing
                                await budgetFormDialog(context, budget: budget);
                              },
                              icon: Icon(
                                Icons.edit_outlined,
                                size: 18.r,
                              ),
                              label: const Text('Edit'),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Navigate to budget list
                                context.pushNamed(AppRoutes.budgetSettings);
                              },
                              icon: Icon(
                                Icons.visibility_outlined,
                                size: 18.r,
                              ),
                              label: const Text('All Budgets'),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          // No active budget, show a card to create one
          return Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                ),
              ],
              color: theme.cardTheme.color ?? Colors.white,
            ),
            child: Padding(
              padding: EdgeInsets.all(24.r),
              child: Column(
                children: [
                  // Empty state illustration
                  Container(
                    width: 80.r,
                    height: 80.r,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 40.r,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    'No Budget Set',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Create a monthly budget to track your spending and save money',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24.h),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await budgetFormDialog(context);
                    },
                    icon: Icon(
                      Icons.add_circle_outline,
                      size: 18.r,
                    ),
                    label: const Text('Create Budget'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: 16.h,
                        horizontal: 32.w,
                      ),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildAmountColumn(
    BuildContext context, {
    required String title,
    required String amount,
    required IconData icon,
    required Color iconColor,
    bool isHighlighted = false,
  }) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(10.r),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20.r,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          amount,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
            color: Colors.white,
            fontSize: isHighlighted ? 18.sp : null,
          ),
        ),
      ],
    );
  }

  IconData _getBudgetIcon(BudgetPeriod period) {
    switch (period) {
      case BudgetPeriod.monthly:
        return Icons.calendar_month;
      case BudgetPeriod.weekly:
        return Icons.view_week;
      case BudgetPeriod.yearly:
        return Icons.calendar_today;
    }
  }
}
