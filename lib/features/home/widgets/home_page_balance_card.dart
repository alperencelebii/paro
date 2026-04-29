import 'package:finance_track/core/colors/app_colors.dart';
import 'package:finance_track/core/models/currency_model.dart';
import 'package:finance_track/core/utils/currency_formatter.dart';
import 'package:finance_track/features/expense_list/bloc/expense_list_bloc.dart';
import 'package:finance_track/features/expense_list/bloc/expense_list_state.dart';
import 'package:finance_track/features/income_list/bloc/income_list_bloc.dart';
import 'package:finance_track/features/income_list/bloc/income_list_state.dart';
import 'package:finance_track/features/profile/currency/screens/currency_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:finance_track/core/localization/localization.dart';

// ignore: must_be_immutable
class HomePageBalanceCard extends StatelessWidget {
  HomePageBalanceCard({super.key, required this.currency});
  Currency currency;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<ExpenseListBloc, ExpenseListState>(
      builder: (context, expenseState) {
        return BlocBuilder<IncomeListBloc, IncomeListState>(
          builder: (context, incomeState) {
            // Calculate total expenses and income
            double totalExpenses = 0;
            double totalIncomes = 0;

            if (expenseState is ExpenseListLoaded) {
              totalExpenses = expenseState.totalAmount;
            }
            if (incomeState.status == IncomeListStatus.loaded) {
              totalIncomes = incomeState.totalIncome;
            }
            final balance = totalIncomes - totalExpenses;
            // Calculate percentage of expenses to income
            final percentage = totalIncomes > 0
                ? (totalExpenses / totalIncomes * 100).clamp(0, 100)
                : 0.0;

            return Container(
              margin: EdgeInsets.only(top: 16.h),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.r),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primaryDark,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(20.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          LocalizedText('Current Balance',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  balance >= 0
                                      ? Icons.trending_up
                                      : Icons.trending_down,
                                  color: balance >= 0
                                      ? AppColors.income
                                      : AppColors.expense,
                                  size: 14.r,
                                ),
                                SizedBox(width: 4.w),
                                LocalizedText(
                                  balance >= 0 ? 'Positive' : 'Negative',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      LocalizedText('${currency.symbol} ${balance.toStringAsFixed(2)}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 28.sp,
                        ),
                      ),

                      // Add a clickable currency indicator
                      GestureDetector(
                        onTap: () => _showCurrencySelectionDialog(context),
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.currency_exchange,
                                color: Colors.white.withValues(alpha: 0.9),
                                size: 14.r,
                              ),
                              SizedBox(width: 4.w),
                              LocalizedText('Currency: ${currency.code}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 12.h),

                      // Progress indicator
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              LocalizedText('Expense ratio',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                              LocalizedText('${percentage.toStringAsFixed(1)}%',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.15),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                percentage < 80
                                    ? AppColors.income
                                    : AppColors.expense,
                              ),
                              minHeight: 6.h,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 24.h),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildBalanceItem(
                            context,
                            'Income',
                            CurrencyFormatter.format(totalIncomes, currency),
                            Icons.arrow_downward,
                            AppColors.income,
                          ),
                          Container(
                            height: 40.h,
                            width: 1.w,
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          _buildBalanceItem(
                            context,
                            'Expenses',
                            CurrencyFormatter.format(totalExpenses, currency),
                            Icons.arrow_upward,
                            AppColors.expense,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCurrencySelectionDialog(BuildContext context) {
    // Call the currency selection dialog function
    showCurrencySelectionDialog(context);
  }

  Widget _buildBalanceItem(
    BuildContext context,
    String title,
    String amount,
    IconData icon,
    Color iconColor,
  ) {
    final theme = Theme.of(context);

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: iconColor,
                size: 16.r,
              ),
              SizedBox(width: 6.w),
              LocalizedText(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          LocalizedText(
            amount,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
