// ignore_for_file: use_build_context_synchronously

import 'package:finance_track/features/expense_list/bloc/expense_list_bloc.dart';
import 'package:finance_track/features/expense_list/bloc/expense_list_event.dart';
import 'package:finance_track/features/transactions/screens/add_transaction_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../data/models/income_model.dart';
import '../../home/widgets/transaction_edit_sheet.dart';
import '../../transactions/utils/transaction_utils.dart';
import '../bloc/income_list_bloc.dart';
import '../bloc/income_list_event.dart';
import '../bloc/income_list_state.dart';
import '../../profile/currency/bloc/currency/currency_bloc.dart';
import '../../profile/currency/bloc/currency/currency_state.dart';
import '../../../core/models/currency_model.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../analytics/widgets/transactions_filter_controls.dart';
import '../../analytics/bloc/transaction_analytics_bloc.dart';
import '../../analytics/bloc/transaction_analytics_state.dart';
import '../../analytics/bloc/transaction_analytics_event.dart' as ta_events;

/// Screen to display the list of incomes
class IncomeListScreen extends StatelessWidget {
  const IncomeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Income History'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: const Color(0xFF00B07B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
            tooltip: 'Filter incomes',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: _IncomeSearchDelegate(
                  incomes: context.read<IncomeListBloc>().state.filteredIncomes,
                ),
              );
            },
            tooltip: 'Search incomes',
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF00B07B),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30.w,
                top: -10.h,
                child: Container(
                  height: 100.r,
                  width: 100.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
              ),
              Positioned(
                left: -20.w,
                bottom: 30.h,
                child: Container(
                  height: 60.r,
                  width: 60.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: BlocBuilder<IncomeListBloc, IncomeListState>(
        builder: (context, state) {
          if (state.status == IncomeListStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state.status == IncomeListStatus.error) {
            return _buildErrorView(context, state.errorMessage);
          } else if (state.filteredIncomes.isEmpty) {
            return _buildEmptyState(context, state);
          } else {
            return _buildIncomeList(context, state);
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await TransactionUtils.showAddTransactionSheet(
            context: context,
            initialType: TransactionType.income,
          );

          // Refresh data
          if (context.mounted) {
            context.read<ExpenseListBloc>().add(const LoadExpenses());
            context.read<IncomeListBloc>().add(const LoadIncomes());
          }
        },
        backgroundColor: const Color(0xFF00B07B),
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  /// Build the empty state widget
  Widget _buildEmptyState(BuildContext context, IncomeListState state) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(32.r),
            decoration: BoxDecoration(
              color: const Color(0xFF00B07B).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              size: 84.r,
              color: const Color(0xFF00B07B),
            ),
          ),
          SizedBox(height: 32.h),
          Text(
            state.selectedCategory != null
                ? 'No ${state.selectedCategory!.displayName} incomes found'
                : 'No incomes recorded yet',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Tap the + button to add a new income',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: 32.h),
          if (state.selectedCategory != null)
            ElevatedButton.icon(
              onPressed: () {
                context
                    .read<IncomeListBloc>()
                    .add(const FilterIncomesByCategory(null));
              },
              icon: const Icon(Icons.filter_alt_off),
              label: const Text('Clear Filter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B07B),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              ),
            ),
        ],
      ),
    );
  }

  /// Build error view
  Widget _buildErrorView(BuildContext context, String errorMessage) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                color: Colors.red.shade400,
                size: 60.r,
              ),
            ),
            SizedBox(height: 24.h),
            SelectableText.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Error loading incomes\n',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                  TextSpan(
                    text: errorMessage,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.red.shade700,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: () {
                context.read<IncomeListBloc>().add(const LoadIncomes());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the income list widget
  Widget _buildIncomeList(BuildContext context, IncomeListState state) {
    return BlocBuilder<TransactionAnalyticsBloc, TransactionAnalyticsState>(
      builder: (context, blocState) {
        if (blocState is TransactionAnalyticsLoaded &&
            blocState.transactionType != ta_events.TransactionType.incomes) {
          context.read<TransactionAnalyticsBloc>().add(
                const ta_events.ToggleTransactionType(
                    ta_events.TransactionType.incomes),
              );
        }

        List<Income> incomes = state.filteredIncomes;
        if (blocState is TransactionAnalyticsLoaded) {
          final filteredIncomeItems = blocState.filteredTransactions
              .where((t) => !t.isExpense)
              .toList();
          final filteredIds = filteredIncomeItems.map((t) => t.id).toSet();

          if (filteredIds.isNotEmpty ||
              TransactionsFilterControls.hasActiveFilters(blocState)) {
            incomes = incomes
                .where((i) =>
                    filteredIds.isEmpty ? true : filteredIds.contains(i.uuid))
                .toList();
          }

          final orderIndex = <String, int>{};
          for (var i = 0; i < filteredIncomeItems.length; i++) {
            orderIndex[filteredIncomeItems[i].id] = i;
          }
          incomes.sort((a, b) {
            final ai = orderIndex[a.uuid] ?? 1 << 30;
            final bi = orderIndex[b.uuid] ?? 1 << 30;
            return ai.compareTo(bi);
          });
        }

        // Decide whether to show date headers (only for date sort)
        final bool showDateHeaders = blocState is TransactionAnalyticsLoaded
            ? (blocState.sortField == ta_events.SortField.date)
            : true;

        // Group incomes by date
        final Map<String, List<Income>> incomesByDate = {};

        for (final income in incomes) {
          final dateKey = _formatDateKey(income.date);
          if (incomesByDate.containsKey(dateKey)) {
            incomesByDate[dateKey]!.add(income);
          } else {
            incomesByDate[dateKey] = [income];
          }
        }

        // Sort the dates in descending order (newest first)
        final sortedDates = incomesByDate.keys.toList()
          ..sort((a, b) => _parseDateKey(b).compareTo(_parseDateKey(a)));

        return RefreshIndicator(
          color: const Color(0xFF00B07B),
          backgroundColor: Theme.of(context).colorScheme.surface,
          onRefresh: () async {
            context.read<IncomeListBloc>().add(const LoadIncomes());
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Applied filters preview under header
              const SliverToBoxAdapter(
                child: AppliedFiltersCard(),
              ),
              // Income Summary Card
              // SliverToBoxAdapter(
              //   child: _IncomeSummaryCard(
              //     totalAmount: state.totalFilteredIncome,
              //     incomes: incomes,
              //   ),
              // ),

              // Section header
              SliverPadding(
                padding: EdgeInsets.all(16.r),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionHeader(
                        context,
                        'All Transactions',
                        Icons.account_balance_wallet,
                        state.selectedCategory?.displayName ?? 'All Categories',
                      ),
                      const TransactionsFilterPill(),
                    ],
                  ),
                ),
              ),

              // Income List grouped by date
              ...sortedDates.map((dateKey) {
                final dailyIncomes = incomesByDate[dateKey]!;

                // Only create a list section if there are transactions for this date
                if (dailyIncomes.isEmpty) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }

                // Get the date from the first income in this group
                final date = dailyIncomes.first.date;

                return SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 16.r),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        // First item is the date header (only when enabled)
                        if (showDateHeaders && index == 0) {
                          return _DateHeader(date: date);
                        }

                        // Map list index to data index depending on header presence
                        final int dataIndex =
                            showDateHeaders ? index - 1 : index;
                        final income = dailyIncomes[dataIndex];
                        return IncomeListItemWidget(income: income);
                      },
                      childCount: showDateHeaders
                          ? dailyIncomes.length + 1 // +1 for the header
                          : dailyIncomes.length,
                    ),
                  ),
                );
              }),

              // Bottom padding
              SliverPadding(
                padding: EdgeInsets.only(bottom: 100.h),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper method to format a date into a string key for grouping
  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Helper method to parse a date key back to DateTime for sorting
  DateTime _parseDateKey(String key) {
    final parts = key.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
    String filterText,
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
              color: const Color(0xFF00B07B),
            ),
            SizedBox(width: 8.w),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        // Container(
        //   padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        //   decoration: BoxDecoration(
        //     color: const Color(0xFF00B07B).withValues(alpha:0.1),
        //     borderRadius: BorderRadius.circular(20.r),
        //   ),
        //   child: Row(
        //     mainAxisSize: MainAxisSize.min,
        //     children: [
        //       Icon(
        //         Icons.filter_list,
        //         size: 14.r,
        //         color: const Color(0xFF00B07B),
        //       ),
        //       SizedBox(width: 4.w),
        //       Text(
        //         filterText,
        //         style: theme.textTheme.bodySmall?.copyWith(
        //           fontWeight: FontWeight.w500,
        //           color: const Color(0xFF00B07B),
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
      ],
    );
  }

  /// Show the filter dialog
  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _FilterDialog(),
    );
  }

  /// Show the delete confirmation dialog
}

/// Date header for grouping incomes by date
class _DateHeader extends StatelessWidget {
  final DateTime date;

  const _DateHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEEE, MMMM d');
    final isToday = _isToday(date);
    final isYesterday = _isYesterday(date);

    String dateText;
    if (isToday) {
      dateText = 'Today';
    } else if (isYesterday) {
      dateText = 'Yesterday';
    } else {
      dateText = dateFormat.format(date);
    }

    return Padding(
      padding: EdgeInsets.only(top: 16.h, bottom: 8.h),
      child: Row(
        children: [
          Text(
            dateText,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF00B07B),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Divider(
              color: const Color(0xFF00B07B).withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }
}

/// Card showing income summary
class _IncomeSummaryCard extends StatefulWidget {
  final double totalAmount;
  final List<Income> incomes;

  const _IncomeSummaryCard({
    required this.totalAmount,
    required this.incomes,
  });

  @override
  State<_IncomeSummaryCard> createState() => _IncomeSummaryCardState();
}

class _IncomeSummaryCardState extends State<_IncomeSummaryCard> {
  // State for selected period - moved outside build method to persist
  late final ValueNotifier<String> selectedPeriod;

  @override
  void initState() {
    super.initState();
    selectedPeriod = ValueNotifier<String>('This Month');
  }

  @override
  void dispose() {
    // Clean up the notifier when the widget is disposed
    selectedPeriod.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    // Function to filter incomes by period and calculate total
    double getTotalForPeriod(String period, List<Income> incomes) {
      final now = DateTime.now();
      final filtered = incomes.where((income) {
        switch (period) {
          case 'This Month':
            return income.date.year == now.year &&
                income.date.month == now.month;
          case 'Last Month':
            final lastMonth = DateTime(now.year, now.month - 1, 1);
            return income.date.year == lastMonth.year &&
                income.date.month == lastMonth.month;
          case 'This Year':
            return income.date.year == now.year;
          case 'All Time':
            return true;
          default:
            return true;
        }
      }).toList();

      return filtered.fold(0, (sum, income) => sum + income.amount);
    }

    // Calculate category breakdown for the selected period
    Map<IncomeCategory, double> getCategoryTotalsForPeriod(
        String period, List<Income> incomes) {
      final Map<IncomeCategory, double> categoryTotals = {};
      final filtered = incomes.where((income) {
        switch (period) {
          case 'This Month':
            return income.date.year == now.year &&
                income.date.month == now.month;
          case 'Last Month':
            final lastMonth = DateTime(now.year, now.month - 1, 1);
            return income.date.year == lastMonth.year &&
                income.date.month == lastMonth.month;
          case 'This Year':
            return income.date.year == now.year;
          case 'All Time':
            return true;
          default:
            return true;
        }
      });

      for (final income in filtered) {
        final category = income.category;
        categoryTotals[category] =
            (categoryTotals[category] ?? 0) + income.amount;
      }

      return categoryTotals;
    }

    return ValueListenableBuilder<String>(
        valueListenable: selectedPeriod,
        builder: (context, period, child) {
          // Get filtered total for selected period
          final periodTotal = getTotalForPeriod(period, widget.incomes);

          // Calculate category breakdown for selected period
          final Map<IncomeCategory, double> categoryTotals =
              getCategoryTotalsForPeriod(period, widget.incomes);

          // Sort categories by amount
          final sortedCategories = categoryTotals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return Container(
            margin: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF009C6D),
                  Color(0xFF00B07B),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00B07B).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(20.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Income',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          _PeriodSelector(
                            theme: theme,
                            currentValue: period,
                            onSelected: (newPeriod) {
                              selectedPeriod.value = newPeriod;
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      BlocBuilder<CurrencyBloc, CurrencyState>(
                        builder: (context, currencyState) {
                          final currency = currencyState is CurrencyLoaded
                              ? currencyState.selectedCurrency
                              : Currencies.inr;

                          return Text(
                            CurrencyFormatter.format(periodTotal, currency),
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 28.sp,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24.r),
                      bottomRight: Radius.circular(24.r),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Top Sources',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      if (sortedCategories.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Text(
                              'No income data available for $period',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        )
                      else
                        ...sortedCategories.take(3).map((entry) {
                          final category = entry.key;
                          final amount = entry.value;
                          final percentage = periodTotal > 0
                              ? (amount / periodTotal) * 100
                              : 0.0;

                          return Padding(
                            padding: EdgeInsets.only(bottom: 12.h),
                            child: _CategoryProgressBar(
                              category: category,
                              amount: amount,
                              percentage: percentage,
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
  }
}

/// Period selector dropdown button
class _PeriodSelector extends StatelessWidget {
  final ThemeData theme;
  final Function(String) onSelected;
  final String currentValue;

  const _PeriodSelector({
    required this.theme,
    required this.onSelected,
    required this.currentValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: Colors.white,
            size: 18.r,
          ),
          style: TextStyle(
            color: Colors.white,
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
          ),
          dropdownColor: const Color(0xFF009C6D),
          isDense: true,
          items: [
            'This Month',
            'Last Month',
            'This Year',
            'All Time',
          ].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onSelected(value);
            }
          },
        ),
      ),
    );
  }
}

/// Category progress bar with icon, name, amount and progress bar
class _CategoryProgressBar extends StatelessWidget {
  final IncomeCategory category;
  final double amount;
  final double percentage;

  const _CategoryProgressBar({
    required this.category,
    required this.amount,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = category.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                category.icon,
                color: color,
                size: 16.r,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                category.displayName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            BlocBuilder<CurrencyBloc, CurrencyState>(
              builder: (context, currencyState) {
                final currency = currencyState is CurrencyLoaded
                    ? currencyState.selectedCurrency
                    : Currencies.inr;

                return Text(
                  CurrencyFormatter.formatCompact(amount, currency),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
            SizedBox(width: 8.w),
            Text(
              '${percentage.toStringAsFixed(0)}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(4.r),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 6.h,
            backgroundColor: const Color(0xFF00B07B).withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

/// Widget for an income list item
class IncomeListItemWidget extends StatelessWidget {
  final Income income;

  const IncomeListItemWidget({super.key, required this.income});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM, yyyy');
    final color = income.category.color;

    return Dismissible(
      key: Key(income.uuid),
      direction: DismissDirection.horizontal,
      background: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF00B07B).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16.r),
        ),
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: 24.w),
        child: Row(
          children: [
            Icon(Icons.edit, color: Colors.white, size: 24.r),
            SizedBox(width: 8.w),
            Text(
              'Edit',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16.r),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 24.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Delete',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 8.w),
            Icon(Icons.delete, color: Colors.white, size: 24.r),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Delete swipe
          final shouldDelete = await _showDeleteConfirmationDialog(context);
          if (shouldDelete) {
            // Delete immediately here to ensure Dismissible is removed from the tree
            context.read<IncomeListBloc>().add(DeleteIncome(income.uuid));
          }
          return shouldDelete;
        } else if (direction == DismissDirection.startToEnd) {
          // Edit swipe
          _editIncome(context);
          return false; // Don't dismiss the item when editing
        }
        return false;
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          color: theme.cardTheme.color ?? Colors.white,
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: 1.w,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20.r),
          highlightColor: color.withValues(alpha: 0.4),
          onTap: () => _showIncomeDetailBottomSheet(context),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
            child: Row(
              children: [
                // Category icon
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    income.category.icon,
                    color: color,
                    size: 24.r,
                  ),
                ),
                SizedBox(width: 16.w),

                // Title and category
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        income.title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '${income.category.displayName} • ${dateFormat.format(income.date)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Amount
                BlocBuilder<CurrencyBloc, CurrencyState>(
                  builder: (context, currencyState) {
                    final currency = currencyState is CurrencyLoaded
                        ? currencyState.selectedCurrency
                        : Currencies.inr;

                    return Text(
                      '+${CurrencyFormatter.format(income.amount, currency)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.greenAccent.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showIncomeDetailBottomSheet(BuildContext context) {
    TransactionUtils.showTransactionDetails(
      context: context,
      transaction: income,
      isExpense: false,
      onEdit: () => _editIncome(context),
      onDelete: () => _confirmAndDelete(context),
    );
  }

  void _editIncome(BuildContext context) {
    TransactionEditSheet.show(
      context: context,
      transaction: income,
      isExpense: false,
    );
  }

  void _confirmAndDelete(BuildContext context) {
    // Use the same delete confirmation dialog
    _showDeleteConfirmationDialog(context).then((confirmed) {
      if (confirmed) {
        context.read<IncomeListBloc>().add(DeleteIncome(income.uuid));
      }
    });
  }

  Future<bool> _showDeleteConfirmationDialog(BuildContext context) async {
    final theme = Theme.of(context);
    final income = this.income; // Capture for animation

    return await showDialog<bool>(
          context: context,
          barrierColor: Colors.black54,
          builder: (context) {
            // Create animation controller
            final animationController = AnimationController(
              vsync: Navigator.of(context),
              duration: const Duration(milliseconds: 400),
            );

            final scaleAnimation = CurvedAnimation(
              parent: animationController,
              curve: Curves.easeOutQuint,
            );

            // Start the animation
            animationController.forward();

            return ScaleTransition(
              scale: scaleAnimation,
              child: AlertDialog(
                backgroundColor: theme.colorScheme.surface,
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.r),
                ),
                contentPadding: EdgeInsets.zero,
                content: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Delete icon with animation
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 32.h),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(24.r),
                            topRight: Radius.circular(24.r),
                          ),
                        ),
                        child: Column(
                          children: [
                            TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0.0, end: 1.0),
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.elasticOut,
                                builder: (context, value, child) {
                                  return Transform.scale(
                                    scale: value,
                                    child: Container(
                                      padding: EdgeInsets.all(20.r),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade400,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.delete_outline_rounded,
                                        size: 40.r,
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                }),
                            SizedBox(height: 24.h),
                            Text(
                              'Delete Income',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Content
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 24.h,
                        ),
                        child: Column(
                          children: [
                            // Transaction info
                            Container(
                              padding: EdgeInsets.all(16.r),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: theme.colorScheme.outlineVariant
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Category icon
                                  Container(
                                    padding: EdgeInsets.all(10.r),
                                    decoration: BoxDecoration(
                                      color: income.category.color
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    child: Icon(
                                      income.category.icon,
                                      color: income.category.color,
                                      size: 20.r,
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          income.title,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 2.h),
                                        BlocBuilder<CurrencyBloc,
                                            CurrencyState>(
                                          builder: (context, currencyState) {
                                            final currency = currencyState
                                                    is CurrencyLoaded
                                                ? currencyState.selectedCurrency
                                                : Currencies.inr;
                                            return Text(
                                              CurrencyFormatter.format(
                                                  income.amount, currency),
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                color: Colors.green.shade600,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 24.h),

                            Text(
                              'This action cannot be undone. Are you sure you want to delete this income?',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Action buttons
                      Padding(
                        padding: EdgeInsets.only(
                          left: 24.w,
                          right: 24.w,
                          bottom: 24.h,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  side: BorderSide(
                                    color: theme.colorScheme.outline,
                                    width: 1.5,
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 12.h),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade400,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 12.h),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ) ??
        false;
  }
}

/// Search delegate for incomes
class _IncomeSearchDelegate extends SearchDelegate<Income?> {
  final List<Income> incomes;

  _IncomeSearchDelegate({required this.incomes});

  @override
  String get searchFieldLabel => 'Search incomes...';

  @override
  TextStyle? get searchFieldStyle => TextStyle(
        fontSize: 16.sp,
        color: Colors.white.withValues(alpha: 0.9),
      );

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF00B07B),
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(
          color: Colors.white,
        ),
        toolbarTextStyle: theme.textTheme.bodyLarge?.copyWith(
          color: Colors.white,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.7),
          fontSize: 16.sp,
        ),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
          tooltip: 'Clear',
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: AnimatedIcon(
        icon: AnimatedIcons.menu_arrow,
        progress: transitionAnimation,
      ),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    if (query.isEmpty) {
      return _buildInitialSearchHints(context);
    }

    final searchResults = _getSearchResults();
    if (searchResults.isEmpty) {
      return _buildNoResultsFound(context);
    }

    return _buildResultsList(context, searchResults);
  }

  List<Income> _getSearchResults() {
    final lowercaseQuery = query.toLowerCase();
    return incomes.where((income) {
      return income.title.toLowerCase().contains(lowercaseQuery) ||
          income.category.displayName.toLowerCase().contains(lowercaseQuery) ||
          income.source.toLowerCase().contains(lowercaseQuery) ||
          (income.notes != null &&
              income.notes!.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  Widget _buildInitialSearchHints(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80.r,
            color: const Color(0xFF00B07B).withValues(alpha: 0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            'Search for incomes by title, category, source, or notes',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsFound(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80.r,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          SizedBox(height: 16.h),
          Text(
            'No results found for "$query"',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Try using different keywords or filters',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(BuildContext context, List<Income> results) {
    return ListView.builder(
      itemCount: results.length,
      padding: EdgeInsets.symmetric(vertical: 12.h),
      itemBuilder: (context, index) {
        final income = results[index];
        return _buildSearchResultItem(context, income);
      },
    );
  }

  Widget _buildSearchResultItem(BuildContext context, Income income) {
    final theme = Theme.of(context);
    final color = income.category.color;
    final dateFormat = DateFormat('dd MMM, yyyy');

    return InkWell(
      onTap: () {
        // Close search and show transaction details
        close(context, income);
        TransactionUtils.showTransactionDetails(
          context: context,
          transaction: income,
          isExpense: false,
          onEdit: () {
            TransactionEditSheet.show(
              context: context,
              transaction: income,
              isExpense: false,
            );
          },
          onDelete: () {
            _showDeleteConfirmation(context, income);
          },
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4.h, horizontal: 16.w),
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          color: theme.cardTheme.color ?? Colors.white,
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Category icon
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                income.category.icon,
                color: color,
                size: 20.r,
              ),
            ),
            SizedBox(width: 12.w),

            // Income details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    income.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '${income.category.displayName} • ${dateFormat.format(income.date)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  if (income.notes != null && income.notes!.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Text(
                      income.notes!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Amount
            BlocBuilder<CurrencyBloc, CurrencyState>(
              builder: (context, currencyState) {
                final currency = currencyState is CurrencyLoaded
                    ? currencyState.selectedCurrency
                    : Currencies.inr;

                return Text(
                  '+${CurrencyFormatter.format(income.amount, currency)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.greenAccent.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to show delete confirmation
  void _showDeleteConfirmation(BuildContext context, Income income) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        // Create animation controller
        final theme = Theme.of(context);
        final animationController = AnimationController(
          vsync: Navigator.of(context),
          duration: const Duration(milliseconds: 400),
        );

        final scaleAnimation = CurvedAnimation(
          parent: animationController,
          curve: Curves.easeOutQuint,
        );

        // Start the animation
        animationController.forward();

        return ScaleTransition(
          scale: scaleAnimation,
          child: AlertDialog(
            backgroundColor: theme.colorScheme.surface,
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.r),
            ),
            contentPadding: EdgeInsets.zero,
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Delete icon with animation
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 32.h),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24.r),
                        topRight: Radius.circular(24.r),
                      ),
                    ),
                    child: Column(
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Container(
                                padding: EdgeInsets.all(20.r),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade400,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.delete_outline_rounded,
                                  size: 40.r,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 24.h),
                        Text(
                          'Delete Income',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 24.h,
                    ),
                    child: Column(
                      children: [
                        // Transaction info
                        Container(
                          padding: EdgeInsets.all(16.r),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Category icon
                              Container(
                                padding: EdgeInsets.all(10.r),
                                decoration: BoxDecoration(
                                  color: income.category.color
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Icon(
                                  income.category.icon,
                                  color: income.category.color,
                                  size: 20.r,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      income.title,
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 2.h),
                                    BlocBuilder<CurrencyBloc, CurrencyState>(
                                      builder: (context, currencyState) {
                                        final currency =
                                            currencyState is CurrencyLoaded
                                                ? currencyState.selectedCurrency
                                                : Currencies.inr;
                                        return Text(
                                          CurrencyFormatter.format(
                                              income.amount, currency),
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: Colors.green.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 24.h),

                        Text(
                          'This action cannot be undone. Are you sure you want to delete this income?',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Action buttons
                  Padding(
                    padding: EdgeInsets.only(
                      left: 24.w,
                      right: 24.w,
                      bottom: 24.h,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              side: BorderSide(
                                color: theme.colorScheme.outline,
                                width: 1.5,
                              ),
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              context
                                  .read<IncomeListBloc>()
                                  .add(DeleteIncome(income.uuid));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade400,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Delete',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Widget for the filter dialog
class _FilterDialog extends StatelessWidget {
  const _FilterDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      clipBehavior: Clip.antiAlias,
      insetPadding: EdgeInsets.all(12.r),
      elevation: 10,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            color: const Color(0xFF00B07B),
            child: Row(
              children: [
                Icon(
                  Icons.filter_list,
                  color: Colors.white,
                  size: 24.r,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'Filter by Category',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close',
                  color: Colors.white,
                  iconSize: 24.r,
                ),
              ],
            ),
          ),

          // Filter options
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _FilterItem(
                    title: 'All Categories',
                    icon: Icons.category,
                    color: const Color(0xFF00B07B),
                    onTap: () {
                      context
                          .read<IncomeListBloc>()
                          .add(const FilterIncomesByCategory(null));
                      Navigator.of(context).pop();
                    },
                  ),
                  const Divider(height: 1),
                  ...IncomeCategory.values.map((category) => Column(
                        children: [
                          _FilterItem(
                            title: category.displayName,
                            icon: category.icon,
                            color: category.color,
                            onTap: () {
                              context
                                  .read<IncomeListBloc>()
                                  .add(FilterIncomesByCategory(category));
                              Navigator.of(context).pop();
                            },
                          ),
                          if (category != IncomeCategory.values.last)
                            const Divider(height: 1),
                        ],
                      )),
                ],
              ),
            ),
          ),

          // Action buttons
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                SizedBox(width: 8.w),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF00B07B),
                  ),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Filter item for the filter dialog
class _FilterItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FilterItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20.r,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
