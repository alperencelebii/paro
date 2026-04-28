import 'package:finance_track/features/budget/screens/budget_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../core/extensions/currency_context_extension.dart';
import '../../../data/models/budget_model.dart';
import '../../../data/repositories/expense_repository.dart';
import '../../../data/repositories/income_repository.dart';
import '../bloc/budget_detail_cubit.dart';
import 'package:finance_track/features/expense_list/screens/expense_list_screen.dart'
    show ExpenseListItemWidget;
import 'package:finance_track/features/income_list/screens/income_list_screen.dart'
    show IncomeListItemWidget;
import '../../../data/models/expense_model.dart';
import '../../../data/models/income_model.dart';
import 'package:finance_track/core/localization/localization.dart';

class BudgetDetailScreen extends StatelessWidget {
  final Budget budget;

  const BudgetDetailScreen({super.key, required this.budget});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final start = DateTime(
      budget.startDate.year,
      budget.startDate.month,
      budget.startDate.day,
    );
    final rawEnd = budget.endDate.isAfter(now) ? now : budget.endDate;
    final end =
        DateTime(rawEnd.year, rawEnd.month, rawEnd.day, 23, 59, 59, 999);
    final initRange = DateTimeRange(start: start, end: end);

    return BlocProvider<BudgetDetailCubit>(
      create: (context) => BudgetDetailCubit(
        budget: budget,
        dateRange: initRange,
        expenseRepository: context.read<ExpenseRepository>(),
        incomeRepository: context.read<IncomeRepository>(),
      )..load(),
      child: _BudgetDetailView(budget: budget),
    );
  }
}

class _BudgetDetailView extends StatelessWidget {
  final Budget budget;
  const _BudgetDetailView({required this.budget});

  @override
  Widget build(BuildContext context) {
    final currency = context.currencySymbol;

    return Scaffold(
      appBar: AppBar(
        title: LocalizedText(budget.title.isNotEmpty
            ? budget.title
            : '${budget.period.displayName} Budget'),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            tooltip: AppLocalizations.tr('Edit Budget'),
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            onPressed: () async {
              await budgetFormDialog(context, budget: budget);
            },
          )
        ],
        centerTitle: false,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<BudgetDetailCubit, BudgetDetailState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: EdgeInsets.all(16.r),
            children: [
              _BudgetHeaderCard(
                budget: budget,
                state: state,
                currency: currency,
              ),
              SizedBox(height: 12.h),
              _AmountSummaryRow(state: state, currency: currency),
              SizedBox(height: 12.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  LocalizedText('Transactions',
                      style: Theme.of(context).textTheme.displayMedium),

                  // Grouping selector only (no manual period chips)
                  _GroupingSelector(
                    budgetPeriod: budget.period,
                    grouping: state.grouping,
                    onChanged: (g) =>
                        context.read<BudgetDetailCubit>().updateGrouping(g),
                  ),
                ],
              ),
              const Divider(),
              SizedBox(height: 8.h),
              _GroupedTransactions(
                state: state,
                currency: currency,
                budgetPeriod: budget.period,
              ),
            ],
          );
        },
      ),
    );
  }

  // Replaced default ListTile with custom analytics transaction tile
}

class _BudgetHeaderCard extends StatelessWidget {
  final Budget budget;
  final BudgetDetailState state;
  final String currency;
  const _BudgetHeaderCard(
      {required this.budget, required this.state, required this.currency});

  @override
  Widget build(BuildContext context) {
    final used = state.totalExpense;
    final total = budget.amount;
    final percent = total <= 0 ? 0.0 : (used / total).clamp(0.0, 1.0);
    final remaining = (total - used).clamp(0, total);

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LocalizedText('Active Budget',
          //     style: Theme.of(context)
          //         .textTheme
          //         .bodySmall
          //         ?.copyWith(color: Colors.grey.shade600)),
          SizedBox(height: 4.h),
          LocalizedText(
              budget.title.isNotEmpty
                  ? budget.title
                  : '${budget.period.displayName} Budget',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.black87, fontWeight: FontWeight.bold)),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocalizedText('Budget Usage',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12.sp)),
                    SizedBox(height: 6.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: LinearProgressIndicator(
                        value: percent,
                        minHeight: 8.r,
                        color: Colors.redAccent,
                        backgroundColor:
                            Colors.greenAccent.withValues(alpha: 0.35),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              _PercentBadge(percent: percent),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _labelValue('Total', '$currency${total.toStringAsFixed(0)}'),
              _labelValue(
                  'Remaining', '$currency${remaining.toStringAsFixed(0)}'),
              _labelValue('Days Left', '${budget.daysRemaining}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _labelValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LocalizedText(label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        SizedBox(height: 4.h),
        LocalizedText(value,
            style: const TextStyle(
                color: Colors.black87, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _PercentBadge extends StatelessWidget {
  final double percent;
  const _PercentBadge({required this.percent});

  @override
  Widget build(BuildContext context) {
    final value = (percent * 100).round();
    return SizedBox(
      height: 42.r,
      width: 42.r,
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
          LocalizedText('$value%',
              style: const TextStyle(
                  color: Colors.black87, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _GroupingSelector extends StatelessWidget {
  final Grouping grouping;
  final ValueChanged<Grouping> onChanged;
  final BudgetPeriod budgetPeriod;
  const _GroupingSelector(
      {required this.grouping,
      required this.onChanged,
      required this.budgetPeriod});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color selectedBg = theme.colorScheme.primary; // primary color
    const Color selectedFg = Colors.white; // white foreground
    const Color unselectedBg = Colors.white; // dull/white background
    final borderColor = Colors.grey.shade300; // subtle border
    return Wrap(
      spacing: 8.w,
      children: [
        ChoiceChip(
          label: LocalizedText('Date Wise',
              style: TextStyle(
                color: grouping == Grouping.date
                    ? selectedFg
                    : Colors.grey.shade800,
                fontWeight: FontWeight.w600,
              )),
          selected: grouping == Grouping.date,
          onSelected: (_) => onChanged(Grouping.date),
          selectedColor: selectedBg,
          backgroundColor: unselectedBg,
          shape: StadiumBorder(side: BorderSide(color: borderColor)),
          showCheckmark: false,
        ),
        if (budgetPeriod == BudgetPeriod.yearly)
          ChoiceChip(
            label: LocalizedText('Monthly',
                style: TextStyle(
                  color: grouping == Grouping.monthly
                      ? selectedFg
                      : Colors.grey.shade800,
                  fontWeight: FontWeight.w600,
                )),
            selected: grouping == Grouping.monthly,
            onSelected: (_) => onChanged(Grouping.monthly),
            backgroundColor: unselectedBg,
            shape: StadiumBorder(side: BorderSide(color: borderColor)),
            showCheckmark: false,
            selectedColor: selectedBg,
          )
        else
          ChoiceChip(
            showCheckmark: false,
            label: LocalizedText('Weekly',
                style: TextStyle(
                  color: grouping == Grouping.weekly
                      ? selectedFg
                      : Colors.grey.shade800,
                  fontWeight: FontWeight.w600,
                )),
            selected: grouping == Grouping.weekly,
            onSelected: (_) => onChanged(Grouping.weekly),
            selectedColor: selectedBg,
            backgroundColor: unselectedBg,
            shape: StadiumBorder(side: BorderSide(color: borderColor)),
          ),
      ],
    );
  }
}

class _AmountSummaryRow extends StatelessWidget {
  final BudgetDetailState state;
  final String currency;
  const _AmountSummaryRow({required this.state, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _pill('Income', '$currency${state.totalIncome.toStringAsFixed(0)}',
            Colors.green),
        _pill('Expense', '$currency${state.totalExpense.toStringAsFixed(0)}',
            Colors.red),
        // _pill(
        //     'Remain',
        //     '$currency${(state.totalIncome - state.totalExpense).toStringAsFixed(0)}',
        //     Colors.blue),
      ],
    );
  }

  Widget _pill(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LocalizedText(label,
                style: TextStyle(
                    color: color.withValues(alpha: 0.9), fontSize: 14.sp)),
            SizedBox(height: 4.h),
            LocalizedText(value,
                style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _GroupedTransactions extends StatelessWidget {
  final BudgetDetailState state;
  final String currency;
  final BudgetPeriod budgetPeriod;
  const _GroupedTransactions(
      {required this.state,
      required this.currency,
      required this.budgetPeriod});

  @override
  Widget build(BuildContext context) {
    final items = [
      ...state.incomes.map((i) => _UnifiedTx(
            date: i.date,
            title: i.title,
            amount: i.amount,
            isIncome: true,
            income: i,
          )),
      ...state.expenses.map((e) => _UnifiedTx(
            date: e.date,
            title: e.title,
            amount: e.amount,
            isIncome: false,
            expense: e,
          )),
    ]..sort((a, b) => b.date.compareTo(a.date));

    final Map<String, List<_UnifiedTx>> groups = {};

    if (state.grouping == Grouping.weekly) {
      // For monthly budgets, use calendar weeks 1-7,8-14,15-21,22-end of month.
      // For other periods, chunk by 7-day windows starting from the range start.
      DateTime anchor;
      if (budgetPeriod == BudgetPeriod.monthly) {
        anchor = DateTime(
            state.dateRange.start.year, state.dateRange.start.month, 1);
      } else {
        anchor = DateTime(state.dateRange.start.year,
            state.dateRange.start.month, state.dateRange.start.day);
      }

      final DateTime rangeEnd = DateTime(state.dateRange.end.year,
          state.dateRange.end.month, state.dateRange.end.day, 23, 59, 59, 999);

      for (final tx in items) {
        int weekIndex;
        DateTime weekStart;
        DateTime weekEnd;

        if (budgetPeriod == BudgetPeriod.monthly) {
          final day = tx.date.day;
          if (day <= 7) {
            weekIndex = 1;
            weekStart = DateTime(tx.date.year, tx.date.month, 1);
            weekEnd = DateTime(tx.date.year, tx.date.month, 7);
          } else if (day <= 14) {
            weekIndex = 2;
            weekStart = DateTime(tx.date.year, tx.date.month, 8);
            weekEnd = DateTime(tx.date.year, tx.date.month, 14);
          } else if (day <= 21) {
            weekIndex = 3;
            weekStart = DateTime(tx.date.year, tx.date.month, 15);
            weekEnd = DateTime(tx.date.year, tx.date.month, 21);
          } else {
            weekIndex = 4;
            weekStart = DateTime(tx.date.year, tx.date.month, 22);
            final lastDay = DateTime(tx.date.year, tx.date.month + 1, 0).day;
            weekEnd = DateTime(tx.date.year, tx.date.month, lastDay);
          }
        } else {
          final diffDays = tx.date.difference(anchor).inDays;
          weekIndex = (diffDays ~/ 7) + 1;
          weekStart = anchor.add(Duration(days: (weekIndex - 1) * 7));
          weekEnd = weekStart.add(const Duration(days: 6));
          if (weekEnd.isAfter(rangeEnd)) {
            weekEnd = rangeEnd;
          }
        }

        final label =
            'Week $weekIndex (${DateFormat('MMM d').format(weekStart)} - ${DateFormat('MMM d').format(weekEnd)})';
        groups.putIfAbsent(label, () => []).add(tx);
      }
    } else if (state.grouping == Grouping.monthly) {
      for (final tx in items) {
        final label = DateFormat('MMM yyyy').format(tx.date);
        groups.putIfAbsent(label, () => []).add(tx);
      }
    } else {
      for (final tx in items) {
        final label = DateFormat('MMM d, yyyy').format(tx.date);
        groups.putIfAbsent(label, () => []).add(tx);
      }
    }

    if (groups.isEmpty) {
      return const LocalizedText('No transactions in this period');
    }

    return Column(
      children: groups.entries.map((entry) {
        final incomeTotal = entry.value
            .where((t) => t.isIncome)
            .fold<double>(0, (s, t) => s + t.amount);
        final expenseTotal = entry.value
            .where((t) => !t.isIncome)
            .fold<double>(0, (s, t) => s + t.amount);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  LocalizedText(entry.key,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  Row(
                    children: [
                      if (incomeTotal > 0) ...[
                        LocalizedText('+$currency${incomeTotal.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      if (incomeTotal > 0 && expenseTotal > 0)
                        SizedBox(width: 12.w),
                      if (expenseTotal > 0)
                        LocalizedText('-$currency${expenseTotal.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  )
                ],
              ),
            ),
            ...entry.value.map((t) {
              if (t.isIncome && t.income != null) {
                return IncomeListItemWidget(income: t.income!);
              } else if (!t.isIncome && t.expense != null) {
                return ExpenseListItemWidget(expense: t.expense!);
              }
              return const SizedBox.shrink();
            }),
            SizedBox(height: 8.h),
          ],
        );
      }).toList(),
    );
  }
}

class _UnifiedTx {
  final DateTime date;
  final String title;
  final double amount;
  final bool isIncome;
  final Expense? expense;
  final Income? income;
  _UnifiedTx(
      {required this.date,
      required this.title,
      required this.amount,
      required this.isIncome,
      this.expense,
      this.income});
}
