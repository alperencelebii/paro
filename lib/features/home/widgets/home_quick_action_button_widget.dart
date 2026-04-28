import 'package:finance_track/core/router/app_router.dart';
import 'package:finance_track/features/expense_list/bloc/expense_list_bloc.dart';
import 'package:finance_track/features/expense_list/bloc/expense_list_state.dart';
import 'package:finance_track/features/expense_list/screens/expense_list_screen.dart';
import 'package:finance_track/features/income_list/bloc/income_list_bloc.dart';
import 'package:finance_track/features/income_list/bloc/income_list_state.dart';
import 'package:finance_track/features/income_list/screens/income_list_screen.dart';
import 'package:finance_track/features/navigation/cubit/navigation_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:finance_track/core/localization/localization.dart';

class HomeQuickActionButtonWidget extends StatelessWidget {
  const HomeQuickActionButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recent Expenses Section
        _buildSectionHeader(
          context,
          'Recent Expenses',
          Icons.receipt_long,
          'View All',
          () {
            // Navigate to expense list screen with direct path
            context.pushNamed(AppRoutes.expenseList);
          },
        ),

        // SizedBox(height: 6.h),

        _buildRecentExpenses(context),

        SizedBox(height: 16.h),

        // Recent Income Section
        _buildSectionHeader(
          context,
          'Recent Income',
          Icons.account_balance_wallet,
          'View All',
          () {
            context.pushNamed(AppRoutes.incomeList);
          },
        ),

        // SizedBox(height: 6.h),

        _buildRecentIncome(context),

        SizedBox(height: 12.h),

        // Analytics Button
        _buildAnalyticsButton(context),

        SizedBox(height: 16.h),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
    String actionText,
    VoidCallback onAction,
  ) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 18.r,
              color: const Color(0xFF6C5CE7),
            ),
            SizedBox(width: 8.w),
            LocalizedText(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          ),
          child: LocalizedText(
            actionText,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6C5CE7),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentExpenses(BuildContext context) {
    return BlocBuilder<ExpenseListBloc, ExpenseListState>(
      builder: (context, state) {
        if (state is ExpenseListLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is ExpenseListError) {
          return Center(
            child: LocalizedText('Error: ${state.message}'),
          );
        } else if (state is ExpenseListLoaded) {
          final expenses = state.expenses;

          if (expenses.isEmpty) {
            return _buildEmptyState(
              context,
              'No expenses yet',
              'Add your first expense to start tracking your spending.',
              Icons.receipt_long,
            );
          }

          // Sort by date, most recent first
          final sortedExpenses = expenses.toList()
            ..sort((a, b) => b.date.compareTo(a.date));

          // Take only the most recent 5 expenses
          final recentExpenses = sortedExpenses.take(5).toList();

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentExpenses.length,
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) {
              final expense = recentExpenses[index];
              return ExpenseListItemWidget(expense: expense);
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildRecentIncome(BuildContext context) {
    return BlocBuilder<IncomeListBloc, IncomeListState>(
      builder: (context, state) {
        if (state.status == IncomeListStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state.status == IncomeListStatus.error) {
          return Center(
            child: LocalizedText('Error: ${state.errorMessage}'),
          );
        } else if (state.status == IncomeListStatus.loaded) {
          final incomes = state.incomes;

          if (incomes.isEmpty) {
            return _buildEmptyState(
              context,
              'No income yet',
              'Add your first income to start tracking your earnings.',
              Icons.account_balance_wallet,
            );
          }

          // Sort by date, most recent first
          final sortedIncomes = incomes.toList()
            ..sort((a, b) => b.date.compareTo(a.date));

          // Take only the most recent 5 incomes
          final recentIncomes = sortedIncomes.take(5).toList();

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentIncomes.length,
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) {
              final income = recentIncomes[index];
              return IncomeListItemWidget(income: income);
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: const Color(0xFF6C5CE7).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 32.r,
              color: const Color(0xFF6C5CE7),
            ),
          ),
          SizedBox(height: 20.h),
          LocalizedText(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          LocalizedText(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsButton(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => _navigateToAnalytics(context),
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6C5CE7),
              Color(0xFF5E57B4),
            ],
          ),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bar_chart_rounded,
                color: Colors.white,
                size: 24.r,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LocalizedText('Financial Analytics',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  LocalizedText('Get insights into your spending habits',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 18.r,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAnalytics(BuildContext context) {
    // Navigate to the analytics screen
    // context.pushNamed(AppRoutes.analytics);
    final String path = AppPaths.getPathForTab(NavigationTab.analytics);
    context.go(path);
    context.read<NavigationCubit>().changeTab(NavigationTab.analytics);
  }
}
