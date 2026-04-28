import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:finance_track/core/localization/localization.dart';

import '../../../core/core.dart';
import '../../../core/extensions/currency_context_extension.dart';
import '../../../data/repositories/expense_repository.dart';
import '../../../data/repositories/income_repository.dart';
import '../cubit/date_wise_expense_cubit.dart';
import '../cubit/dashboard_state.dart';

/// Bar chart widget showing date-wise expenses for the dashboard
class DateWiseExpenseChart extends StatelessWidget {
  final DashboardLoaded state;
  final int days;

  const DateWiseExpenseChart({
    super.key,
    required this.state,
    this.days = 10,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DateWiseExpenseCubit(
        expenseRepository: context.read<ExpenseRepository>(),
        incomeRepository: context.read<IncomeRepository>(),
      )..loadDateWiseData(days: days),
      child: BlocBuilder<DateWiseExpenseCubit, DateWiseExpenseState>(
        builder: (context, expenseState) {
          if (expenseState is DateWiseExpenseLoading) {
            return _buildLoadingState(context);
          }

          if (expenseState is DateWiseExpenseError) {
            return _buildErrorState(context, expenseState.message);
          }

          if (expenseState is DateWiseExpenseLoaded) {
            return _buildChart(context, expenseState);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Center(
        child: LocalizedText('Error: $message',
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context, DateWiseExpenseLoaded state) {
    final currency = context.selectedCurrency;
    final formatter = NumberFormat.currency(
      symbol: currency.symbol,
      decimalDigits: 0,
    );

    // Calculate max value for scaling
    final maxExpense = state.dailyData.isEmpty
        ? 100.0
        : state.dailyData.map((e) => e.expense).reduce((a, b) => a > b ? a : b);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with total and change
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocalizedText(
                      formatter.format(state.totalExpense),
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        LocalizedText('Last $days Days',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: state.changePercentage >= 0
                                ? Colors.red.shade50
                                : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: LocalizedText('${state.changePercentage >= 0 ? '+' : ''}${state.changePercentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: state.changePercentage >= 0
                                  ? Colors.red.shade700
                                  : Colors.green.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  context.pushNamed(AppRoutes.dateWiseExpense);
                },
                child: LocalizedText('View More',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6C63FF),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          // Bar Chart
          SizedBox(
            height: 200.h,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: state.dailyData.map((data) {
                final height =
                    maxExpense > 0 ? (data.expense / maxExpense) * 180.h : 0.0;

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Amount label above bar
                        if (data.expense > 0)
                          Padding(
                            padding: EdgeInsets.only(bottom: 4.h),
                            child: LocalizedText(
                              formatter.format(data.expense),
                              style: TextStyle(
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        // Bar
                        Container(
                          height: height,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF08080),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(4.r),
                              bottom: Radius.circular(4.r),
                            ),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        // Date label
                        LocalizedText(
                          DateFormat('MMM').format(data.date),
                          style: TextStyle(
                            fontSize: 9.sp,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        LocalizedText(
                          DateFormat('d').format(data.date),
                          style: TextStyle(
                            fontSize: 9.sp,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
