import 'package:finance_track/core/router/app_router.dart';
import 'package:finance_track/data/models/budget_model.dart';
import 'package:finance_track/data/models/expense_model.dart';
import 'package:finance_track/data/repositories/expense_repository.dart';
import 'package:finance_track/features/budget/bloc/budget_bloc/budget_bloc.dart';
import 'package:finance_track/features/expense_list/bloc/expense_list_bloc.dart';
import 'package:finance_track/features/expense_list/bloc/expense_list_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:finance_track/core/extensions/currency_context_extension.dart';

class HomeActiveBudgetCard extends StatefulWidget {
  const HomeActiveBudgetCard({super.key});

  @override
  State<HomeActiveBudgetCard> createState() => _HomeActiveBudgetCardState();
}

class _HomeActiveBudgetCardState extends State<HomeActiveBudgetCard> {
  double _periodExpenses = 0;
  int? _lastBudgetId;

  // void _requirePremium(VoidCallback onAllowed) {
  //   final subscriptionCubit = context.read<SubscriptionCubit>();
  //   // final purchasesCubit = context.read<PurchasesCubit>();
  //   subscriptionCubit.ensureProStatus().then((isPro) {
  //     if (!mounted) return;
  //     if (isPro) {
  //       onAllowed();
  //     } else {
  //       // purchasesCubit.loadOfferings();
  //       context.pushNamed(AppRoutes.purchasesPage);
  //     }
  //   });
  // }

  @override
  void initState() {
    super.initState();
    // Ensure budgets are loaded when this widget appears on Home
    final bloc = context.read<BudgetBloc>();
    if (bloc.state is! BudgetLoaded) {
      bloc.add(const LoadBudget());
    }
  }

  void _calculatePeriodExpenses(Budget budget, List<Expense> expenses) {
    final now = DateTime.now();

    DateTime start;
    DateTime end;
    switch (budget.period) {
      case BudgetPeriod.weekly:
        final weekday = now.weekday % 7; // 0 for Sunday
        start = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: weekday));
        end =
            DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
        break;
      case BudgetPeriod.monthly:
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0).add(const Duration(days: 1));
        break;
      case BudgetPeriod.yearly:
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year + 1, 1, 1);
        break;
    }

    final sum = expenses
        .where((e) => e.date.isAfter(start) && e.date.isBefore(end))
        .fold<double>(0, (s, e) => s + e.amount);
    if (mounted) setState(() => _periodExpenses = sum);
  }

  Future<void> _loadThisPeriodExpenses(Budget budget) async {
    final repo = context.read<ExpenseRepository>();
    final all = await repo.getAllExpenses();
    _calculatePeriodExpenses(budget, all);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BudgetBloc, BudgetState>(
      builder: (context, budgetState) {
        if (budgetState is! BudgetLoaded) {
          return _placeholder();
        }

        final budget = budgetState.activeBudget;
        if (budget == null) return _emptyState();

        // Listen to expense changes for real-time updates
        return BlocListener<ExpenseListBloc, ExpenseListState>(
          listener: (context, expenseState) {
            if (expenseState is ExpenseListLoaded) {
              // Recalculate when expenses change
              if (_lastBudgetId != budget.id) {
                _lastBudgetId = budget.id;
              }
              _calculatePeriodExpenses(budget, expenseState.expenses);
            }
          },
          child: BlocBuilder<ExpenseListBloc, ExpenseListState>(
            builder: (context, expenseState) {
              // Initial load when budget changes
              if (_lastBudgetId != budget.id) {
                _lastBudgetId = budget.id;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    if (expenseState is ExpenseListLoaded) {
                      _calculatePeriodExpenses(budget, expenseState.expenses);
                    } else {
                      _loadThisPeriodExpenses(budget);
                    }
                  }
                });
              }

              final total = budget.amount.toDouble();
              final spent = _periodExpenses;
              final percent =
                  total <= 0 ? 0.0 : (spent / total).clamp(0.0, 1.0);

              return _compactAnalyticsCard(
                context: context,
                title: budget.title.isNotEmpty
                    ? budget.title
                    : '${budget.period.displayName} Budget',
                percent: percent,
                spent: spent,
                total: total,
                onTap: () {
                  //   _requirePremium(() {
                  //   context.pushNamed(
                  //     AppRoutes.budgetDetail,
                  //     extra: {'budget': budget},
                  //   );
                  // });
                  context.pushNamed(
                    AppRoutes.budgetDetail,
                    extra: {'budget': budget},
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _placeholder() {
    return Container(
      width: double.infinity,
      // margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      height: 150.h,
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('No active budget'),
          TextButton(
            onPressed: () {
              // _requirePremium(() {
              // context.pushNamed(AppRoutes.budgetSettings);
            // });
              context.pushNamed(AppRoutes.budgetSettings);
            },
            child: const Text('Set Budget'),
          )
        ],
      ),
    );
  }

  Widget _compactAnalyticsCard({
    required BuildContext context,
    required String title,
    required double percent,
    required double spent,
    required double total,
    required VoidCallback onTap,
  }) {
    final percentText = '${(percent * 100).round()}%';
    final currency = context.currencySymbol;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          width: double.infinity,
          // margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(0, 4),
                blurRadius: 12,
              ),
            ],
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  SizedBox(
                    height: 44.r,
                    width: 44.r,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: 1,
                          strokeWidth: 5.r,
                          color: Colors.greenAccent,
                          backgroundColor: Colors.transparent,
                        ),
                        CircularProgressIndicator(
                          value: percent,
                          strokeWidth: 5.r,
                          color: Colors.redAccent,
                          backgroundColor: Colors.transparent,
                        ),
                        Text(
                          percentText,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: LinearProgressIndicator(
                  value: percent,
                  minHeight: 8.r,
                  color: Colors.redAccent, // used
                  backgroundColor:
                      Colors.greenAccent.withValues(alpha: 0.35), // unused
                ),
              ),
              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Used $currency${spent.toStringAsFixed(0)}',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  Text(
                    'Total $currency${total.toStringAsFixed(0)}',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
