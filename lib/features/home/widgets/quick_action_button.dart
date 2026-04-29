import 'package:finance_track/core/colors/app_colors.dart';
import 'package:finance_track/core/router/app_router.dart';
import 'package:finance_track/features/expense_list/bloc/expense_list_bloc.dart';
import 'package:finance_track/features/expense_list/bloc/expense_list_event.dart';
import 'package:finance_track/features/income_list/bloc/income_list_bloc.dart';
import 'package:finance_track/features/income_list/bloc/income_list_event.dart';
import 'package:finance_track/features/navigation/cubit/navigation_cubit.dart';
import 'package:finance_track/features/transactions/utils/transaction_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:finance_track/core/localization/localization.dart';

class HomeQuickActionButton extends StatelessWidget {
  const HomeQuickActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionButton(
          context,
          'Add Expense',
          Icons.shopping_bag_outlined,
          AppColors.expense,
          () async {
            final result = await TransactionUtils.showAddExpenseSheet(
              context: context,
            );

            if (result == true) {
              // Refresh the expense list
              if (context.mounted) {
                context.read<ExpenseListBloc>().add(const LoadExpenses());
              }
            }
          },
        ),
        _buildActionButton(
          context,
          'Add Income',
          Icons.account_balance_wallet_outlined,
          AppColors.income,
          () async {
            final result = await TransactionUtils.showAddIncomeSheet(
              context: context,
            );

            if (result == true) {
              // Refresh the income list
              if (context.mounted) {
                context.read<IncomeListBloc>().add(const LoadIncomes());
              }
            }
          },
        ),
        _buildActionButton(
          context,
          'Analytics',
          Icons.insert_chart_outlined_rounded,
          AppColors.primary,
          () {
            _navigateToAnalytics(context);
          },
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color,
                color.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20.r,
                ),
              ),
              SizedBox(height: 8.h),
              LocalizedText(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
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
