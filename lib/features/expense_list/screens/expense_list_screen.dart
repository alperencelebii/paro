// ignore_for_file: use_build_context_synchronously

import 'package:finance_track/features/income_list/bloc/income_list_bloc.dart';
import 'package:finance_track/features/income_list/bloc/income_list_event.dart';
import 'package:finance_track/features/transactions/screens/add_transaction_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../data/models/expense_model.dart';
import 'add_expense_bottom_sheet.dart';
import '../bloc/expense_list_bloc.dart';
import '../bloc/expense_list_event.dart';
import '../bloc/expense_list_state.dart';
import '../../home/widgets/transaction_edit_sheet.dart';
import '../../transactions/utils/transaction_utils.dart';
import '../../profile/currency/bloc/currency/currency_bloc.dart';
import '../../profile/currency/bloc/currency/currency_state.dart';
import '../../../core/models/currency_model.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../analytics/widgets/transactions_filter_controls.dart';
import '../../analytics/bloc/transaction_analytics_bloc.dart';
import '../../analytics/bloc/transaction_analytics_state.dart';
import '../../analytics/bloc/transaction_analytics_event.dart' as ta_events;
import 'package:finance_track/core/localization/localization.dart';

class ExpenseListScreenPage extends StatelessWidget {
  const ExpenseListScreenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ExpenseListScreen();
  }
}

/// Screen to display the list of expenses
class ExpenseListScreen extends StatelessWidget {
  const ExpenseListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        context.read<TransactionAnalyticsBloc>().add(
              const ta_events.ResetFilters(),
            );
        return true;
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          title: const LocalizedText('Expense History'),
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              context.read<TransactionAnalyticsBloc>().add(
                    const ta_events.ResetFilters(),
                  );
              Navigator.of(context).pop();
            },
          ),
          centerTitle: false,
          backgroundColor: const Color(0xFFF25F5C),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () => _showFilterDialog(context),
              tooltip: AppLocalizations.tr('Filter expenses'),
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                final state = context.read<ExpenseListBloc>().state;
                if (state is ExpenseListLoaded) {
                  showSearch(
                    context: context,
                    delegate: _ExpenseSearchDelegate(
                      expenses: state.filteredExpenses,
                      onShowExpenseDetails: _showExpenseEditBottomSheet,
                    ),
                  );
                }
              },
              tooltip: AppLocalizations.tr('Search expenses'),
            ),
          ],
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF25F5C),
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
        body: BlocBuilder<ExpenseListBloc, ExpenseListState>(
          builder: (context, state) {
            if (state is ExpenseListLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (state is ExpenseListError) {
              return _ErrorView(message: state.message);
            } else if (state is ExpenseListLoaded) {
              return _ExpenseListView(state: state);
            }
            return const SizedBox.shrink();
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await TransactionUtils.showAddTransactionSheet(
              context: context,
              initialType: TransactionType.expense,
            );

            // Refresh data
            if (context.mounted) {
              context.read<ExpenseListBloc>().add(const LoadExpenses());
              context.read<IncomeListBloc>().add(const LoadIncomes());
            }
          },
          elevation: 4,
          backgroundColor: const Color(0xFFF25F5C),
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _FilterDialog(),
    );
  }

  void _showExpenseEditBottomSheet(BuildContext context, Expense expense) {
    TransactionEditSheet.show(
      context: context,
      transaction: expense,
      isExpense: true,
    );
  }
}

/// Widget to display the list of expenses
class _ExpenseListView extends StatelessWidget {
  final ExpenseListLoaded state;

  const _ExpenseListView({required this.state});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionAnalyticsBloc, TransactionAnalyticsState>(
      builder: (context, blocState) {
        // Ensure analytics is in expenses mode
        if (blocState is TransactionAnalyticsLoaded &&
            blocState.transactionType != ta_events.TransactionType.expenses) {
          context.read<TransactionAnalyticsBloc>().add(
                const ta_events.ToggleTransactionType(
                    ta_events.TransactionType.expenses),
              );
        }

        // Start with existing category-filtered list
        List<Expense> expenses = state.filteredExpenses;

        if (blocState is TransactionAnalyticsLoaded) {
          final filteredExpenseItems =
              blocState.filteredTransactions.where((t) => t.isExpense).toList();
          final filteredIds = filteredExpenseItems.map((t) => t.id).toSet();

          // Apply filtering if any analytics filter active
          if (filteredIds.isNotEmpty ||
              TransactionsFilterControls.hasActiveFilters(blocState)) {
            expenses = expenses
                .where((e) =>
                    filteredIds.isEmpty ? true : filteredIds.contains(e.uuid))
                .toList();
          }

          // Apply analytics sort order
          final orderIndex = <String, int>{};
          for (var i = 0; i < filteredExpenseItems.length; i++) {
            orderIndex[filteredExpenseItems[i].id] = i;
          }
          expenses.sort((a, b) {
            final ai = orderIndex[a.uuid] ?? 1 << 30;
            final bi = orderIndex[b.uuid] ?? 1 << 30;
            return ai.compareTo(bi);
          });
        }

        final bool showDateHeaders = blocState is TransactionAnalyticsLoaded
            ? (blocState.sortField == ta_events.SortField.date)
            : true;

        if (expenses.isEmpty) {
          return _EmptyExpenseView();
        }

        return RefreshIndicator(
          color: Theme.of(context).colorScheme.primary,
          backgroundColor: Theme.of(context).colorScheme.surface,
          onRefresh: () async {
            context.read<ExpenseListBloc>().add(const LoadExpenses());
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Applied filters preview under header
              const SliverToBoxAdapter(
                child: AppliedFiltersCard(),
              ),

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
                        state.filterCategory?.displayName ?? 'All Categories',
                      ),
                      const TransactionsFilterPill(),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 16.r),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final expense = expenses[index];

                      if (showDateHeaders &&
                          (index == 0 ||
                              _shouldShowDateHeader(expenses, index))) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _DateHeader(date: expense.date),
                            ExpenseListItemWidget(expense: expense),
                          ],
                        );
                      }

                      return ExpenseListItemWidget(expense: expense);
                    },
                    childCount: expenses.length,
                  ),
                ),
              ),
              SliverPadding(padding: EdgeInsets.only(bottom: 100.h)),
            ],
          ),
        );
      },
    );
  }

  bool _shouldShowDateHeader(List<Expense> expenses, int index) {
    if (index == 0) return true;

    final currentDate = expenses[index].date;
    final previousDate = expenses[index - 1].date;

    return !_isSameDay(currentDate, previousDate);
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}

/// Date header for grouping expenses by date
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
          LocalizedText(
            dateText,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.red.shade400,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Divider(
              color: Colors.red.shade400.withValues(alpha: 0.2),
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

/// Widget for an expense list item
class ExpenseListItemWidget extends StatelessWidget {
  final Expense expense;

  const ExpenseListItemWidget({
    super.key,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM, yyyy');
    final theme = Theme.of(context);
    final color = expense.category.color;

    return Dismissible(
      key: Key(expense.uuid),
      direction: DismissDirection.horizontal,
      background: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF25F5C).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16.r),
        ),
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: 24.w),
        child: Row(
          children: [
            Icon(Icons.edit, color: Colors.white, size: 24.r),
            SizedBox(width: 8.w),
            LocalizedText('Edit',
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
            LocalizedText('Delete',
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
          final confirmed = await _showDeleteConfirmationDialog(context);
          if (confirmed) {
            // Delete immediately here to ensure Dismissible is removed from the tree
            context.read<ExpenseListBloc>().add(DeleteExpense(expense.uuid));
          }
          return confirmed;
        } else if (direction == DismissDirection.startToEnd) {
          // Edit swipe
          editExpense(context);
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
          onTap: () => showExpenseDetailBottomSheet(context),
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
                    expense.category.icon,
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
                      LocalizedText(
                        expense.title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      LocalizedText('${expense.category.displayName} • ${dateFormat.format(expense.date)}',
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

                    return LocalizedText('−${CurrencyFormatter.format(expense.amount, currency)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.redAccent,
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

  /// Show expense detail bottom sheet
  void showExpenseDetailBottomSheet(BuildContext context) {
    TransactionUtils.showTransactionDetails(
      context: context,
      transaction: expense,
      isExpense: true,
      onEdit: () => editExpense(context),
      onDelete: () => confirmAndDelete(context),
    );
  }

  /// Edit expense
  void editExpense(BuildContext context) {
    TransactionEditSheet.show(
      context: context,
      transaction: expense,
      isExpense: true,
    );
  }

  /// Confirm and delete expense
  void confirmAndDelete(BuildContext context) {
    // Use the same delete confirmation dialog
    _showDeleteConfirmationDialog(context).then((confirmed) {
      if (confirmed) {
        context.read<ExpenseListBloc>().add(DeleteExpense(expense.uuid));
      }
    });
  }

  /// Show delete confirmation dialog
  Future<bool> _showDeleteConfirmationDialog(BuildContext context) async {
    final theme = Theme.of(context);
    final expense = this.expense; // Capture for animation

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
                            LocalizedText('Delete Expense',
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
                                      color: expense.category.color
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    child: Icon(
                                      expense.category.icon,
                                      color: expense.category.color,
                                      size: 20.r,
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        LocalizedText(
                                          expense.title,
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
                                            return LocalizedText(
                                              CurrencyFormatter.format(
                                                  expense.amount, currency),
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                color: Colors.red.shade400,
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

                            LocalizedText('This action cannot be undone. Are you sure you want to delete this expense?',
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
                                child: LocalizedText('Cancel',
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
                                child: const LocalizedText('Delete',
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

/// Dialog for displaying and editing expense details
class _ExpenseDetailsDialog extends StatefulWidget {
  final Expense expense;
  final Function(Expense) onSave;

  const _ExpenseDetailsDialog({
    required this.expense,
    required this.onSave,
  });

  @override
  State<_ExpenseDetailsDialog> createState() => _ExpenseDetailsDialogState();
}

class _ExpenseDetailsDialogState extends State<_ExpenseDetailsDialog> {
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  late TextEditingController _paymentMethodController;
  late DateTime _selectedDate;
  late ExpenseCategory _selectedCategory;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.expense.title);
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    _amountController = TextEditingController(
        text: currencyFormat.format(widget.expense.amount));
    _notesController = TextEditingController(text: widget.expense.notes ?? '');
    _paymentMethodController =
        TextEditingController(text: widget.expense.paymentMethod);
    _selectedDate = widget.expense.date;
    _selectedCategory = widget.expense.category;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _paymentMethodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('HH:mm');
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final theme = Theme.of(context);
    final color = _getCategoryColor(_selectedCategory);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 8,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with category icon and edit/close buttons
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _selectedCategory.icon,
                      color: color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LocalizedText('Expense Details',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        LocalizedText(
                          _selectedCategory.displayName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_isEditing)
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        setState(() {
                          _isEditing = true;
                        });
                      },
                      tooltip: AppLocalizations.tr('Edit expense'),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: AppLocalizations.tr('Close'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Content - View Mode or Edit Mode
              if (_isEditing) ...[
                // Edit Mode
                _buildEditField(
                  label: AppLocalizations.tr('Title'),
                  controller: _titleController,
                  prefixIcon: Icons.title,
                ),
                const SizedBox(height: 16),
                _buildEditField(
                  label: AppLocalizations.tr('Amount'),
                  controller: _amountController,
                  prefixIcon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                // Category Dropdown
                LocalizedText('Category',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.5),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<ExpenseCategory>(
                      value: _selectedCategory,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down),
                      borderRadius: BorderRadius.circular(12),
                      items: ExpenseCategory.values.map((category) {
                        final categoryColor = _getCategoryColor(category);
                        return DropdownMenuItem<ExpenseCategory>(
                          value: category,
                          child: Row(
                            children: [
                              Icon(
                                category.icon,
                                color: categoryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              LocalizedText(category.displayName),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Date Picker
                LocalizedText('Date & Time',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _selectDateTime(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today),
                        const SizedBox(width: 12),
                        LocalizedText('${dateFormat.format(_selectedDate)} at ${timeFormat.format(_selectedDate)}',
                        ),
                        const Spacer(),
                        const Icon(Icons.edit_calendar),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildEditField(
                  label: AppLocalizations.tr('Payment Method'),
                  controller: _paymentMethodController,
                  prefixIcon: Icons.payment,
                ),
                const SizedBox(height: 16),
                _buildEditField(
                  label: AppLocalizations.tr('Notes (Optional)'),
                  controller: _notesController,
                  prefixIcon: Icons.note,
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _isEditing = false;

                            // Reset to original values
                            _titleController.text = widget.expense.title;
                            _amountController.text =
                                currencyFormat.format(widget.expense.amount);
                            _notesController.text = widget.expense.notes ?? '';
                            _paymentMethodController.text =
                                widget.expense.paymentMethod;
                            _selectedDate = widget.expense.date;
                            _selectedCategory = widget.expense.category;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const LocalizedText('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: _saveChanges,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const LocalizedText('Save'),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // View Mode
                // Title and Amount
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LocalizedText('Title',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 4),
                          LocalizedText(
                            widget.expense.title,
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        LocalizedText('Amount',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        LocalizedText(
                          currencyFormat.format(widget.expense.amount),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                // Date and Time
                _buildInfoItem(
                  context: context,
                  icon: Icons.calendar_today,
                  title: 'Date',
                  value: dateFormat.format(widget.expense.date),
                ),
                const SizedBox(height: 12),
                _buildInfoItem(
                  context: context,
                  icon: Icons.access_time,
                  title: 'Time',
                  value: timeFormat.format(widget.expense.date),
                ),
                const SizedBox(height: 12),

                // Payment Method
                if (widget.expense.paymentMethod.isNotEmpty) ...[
                  _buildInfoItem(
                    context: context,
                    icon: Icons.payment,
                    title: 'Payment Method',
                    value: widget.expense.paymentMethod,
                  ),
                  const SizedBox(height: 12),
                ],

                // Notes (if any)
                if (widget.expense.notes?.isNotEmpty ?? false) ...[
                  LocalizedText('Notes',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: LocalizedText(
                      widget.expense.notes!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build form fields
  Widget _buildEditField({
    required String label,
    required TextEditingController controller,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LocalizedText(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
              ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: Icon(prefixIcon),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to build info items
  Widget _buildInfoItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LocalizedText(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            LocalizedText(
              value,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Method to handle date and time selection
  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  // Method to save changes
  void _saveChanges() {
    double amount;
    bool amountChanged = false;

    try {
      // Only attempt to parse the amount if it has been changed from its initial value
      final currencyFormat = NumberFormat.currency(symbol: '\$');
      final originalAmountText = currencyFormat.format(widget.expense.amount);
      final currentAmountText = _amountController.text.trim();

      // Check if the amount was modified
      amountChanged = currentAmountText != originalAmountText;

      if (amountChanged) {
        // Clean up the input for parsing - remove currency symbols, commas, spaces
        String cleanedAmount = currentAmountText
            .replaceAll(RegExp(r'[^\d.,]'),
                '') // Remove anything that's not a digit, dot or comma
            .replaceAll(RegExp(r','),
                '.'); // Replace commas with dots for locales that use comma as decimal

        // If we have multiple dots after replacing commas, keep only the last one (decimal separator)
        final dotCount = '.'.allMatches(cleanedAmount).length;
        if (dotCount > 1) {
          final lastDotIndex = cleanedAmount.lastIndexOf('.');
          cleanedAmount =
              cleanedAmount.substring(0, lastDotIndex).replaceAll('.', '') +
                  cleanedAmount.substring(lastDotIndex);
        }

        // Now parse the amount
        amount = double.parse(cleanedAmount);
      } else {
        // Use the original amount if not changed
        amount = widget.expense.amount;
      }

      // Validate title
      if (_titleController.text.trim().isEmpty) {
        _showValidationError('Title cannot be empty');
        return;
      }

      // Validate amount
      if (amount <= 0) {
        _showValidationError('Amount must be greater than zero');
        return;
      }

      // Create updated expense object
      final updatedExpense = widget.expense.copyWith(
        title: _titleController.text.trim(),
        amount: amount,
        date: _selectedDate,
        category: _selectedCategory,
        notes: _notesController.text.trim(),
        paymentMethod: _paymentMethodController.text.trim(),
      );

      // Save the expense
      widget.onSave(updatedExpense);
    } catch (e) {
      if (amountChanged) {
        _showValidationError('Please enter a valid amount format');
      } else {
        // This should never happen if we reuse the original amount correctly
        _showValidationError('An unexpected error occurred: $e');
      }
    }
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: LocalizedText(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

/// Empty state view when no expenses are available
class _EmptyExpenseView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.receipt_long,
                  size: 84,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              LocalizedText('No expenses yet',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              LocalizedText('Start tracking your expenses by adding your first transaction',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await AddExpenseBottomSheet.show(context);

                  if (result == true) {
                    if (context.mounted) {
                      context.read<ExpenseListBloc>().add(const LoadExpenses());
                    }
                  }
                },
                icon: const Icon(Icons.add),
                label: const LocalizedText('Add Your First Expense'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget to display an error message
class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                color: Colors.red.shade400,
                size: 60,
              ),
            ),
            const SizedBox(height: 24),
            SelectableText.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: AppLocalizations.tr('Error loading expenses\n'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                  TextSpan(
                    text: message,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.red.shade700,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<ExpenseListBloc>().add(const LoadExpenses());
              },
              icon: const Icon(Icons.refresh),
              label: const LocalizedText('Try Again'),
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
}

/// Dialog to filter expenses by category
class _FilterDialog extends StatefulWidget {
  const _FilterDialog();

  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  // Track selected categories for multi-select
  final Set<ExpenseCategory?> _selectedCategories = {};
  bool _isAllSelected = true;

  @override
  void initState() {
    super.initState();
    // Get current filter state from the bloc
    final currentState = context.read<ExpenseListBloc>().state;
    if (currentState is ExpenseListLoaded) {
      if (currentState.filterCategory != null) {
        _selectedCategories.add(currentState.filterCategory);
        _isAllSelected = false;
      } else if (currentState.filterCategories != null &&
          currentState.filterCategories!.isNotEmpty) {
        // Initialize from multi-category filter
        _selectedCategories.addAll(currentState.filterCategories!);
        _isAllSelected = false;
      } else {
        // No filter is active, so "All Categories" is selected
        _isAllSelected = true;
        _selectedCategories.clear();
      }
    }
  }

  void _toggleCategory(ExpenseCategory? category) {
    setState(() {
      if (category == null) {
        // Handle "All Categories" selection
        _isAllSelected = true;
        _selectedCategories.clear();
      } else {
        // Handle specific category selection
        if (_isAllSelected) {
          // If "All Categories" was selected, deselect it and select only this category
          _isAllSelected = false;
          _selectedCategories.clear();
          _selectedCategories.add(category);
        } else {
          // Toggle the specific category
          if (_selectedCategories.contains(category)) {
            _selectedCategories.remove(category);
            // If no categories selected, default to "All"
            if (_selectedCategories.isEmpty) {
              _isAllSelected = true;
            }
          } else {
            _selectedCategories.add(category);
          }
        }
      }
    });
  }

  void _applyFilters() {
    if (_isAllSelected) {
      // Clear all filters when "All Categories" is selected
      context.read<ExpenseListBloc>().add(const ClearFilters());
    } else if (_selectedCategories.length == 1) {
      // Apply single category filter
      final category = _selectedCategories.first;
      context.read<ExpenseListBloc>().add(FilterExpensesByCategory(category));
    } else if (_selectedCategories.length > 1) {
      // Filter by multiple categories
      // Cast to remove the nullable aspect since we know these are all non-null
      final nonNullCategories =
          _selectedCategories.whereType<ExpenseCategory>().toSet();

      context.read<ExpenseListBloc>().add(
            FilterExpensesByCategories(nonNullCategories),
          );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.all(12),
      elevation: 10,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            color: theme.colorScheme.primaryContainer,
            child: Row(
              children: [
                Icon(
                  Icons.filter_list,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 25,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LocalizedText('Filter Expenses',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 25),
                  onPressed: () => Navigator.pop(context),
                  tooltip: AppLocalizations.tr('Close'),
                  color: theme.colorScheme.onPrimaryContainer,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                  visualDensity: VisualDensity.compact,
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
                  // All Categories option
                  _FilterItemSelectable(
                    title: 'All Categories',
                    icon: Icons.category,
                    color: theme.colorScheme.primary,
                    isSelected: _isAllSelected,
                    onTap: () => _toggleCategory(null),
                  ),
                  const Divider(height: 1),

                  // Individual category options
                  ...ExpenseCategory.values.map((category) => Column(
                        children: [
                          _FilterItemSelectable(
                            title: category.displayName,
                            icon: category.icon,
                            color: _getCategoryColor(category),
                            isSelected: !_isAllSelected &&
                                _selectedCategories.contains(category),
                            onTap: () => _toggleCategory(category),
                          ),
                          if (category != ExpenseCategory.values.last)
                            const Divider(height: 1),
                        ],
                      )),
                ],
              ),
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const LocalizedText('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _applyFilters,
                  child: const LocalizedText('Apply'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Selectable filter item for the filter dialog
class _FilterItemSelectable extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterItemSelectable({
    required this.title,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isSelected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: LocalizedText(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper function to get color for category
Color _getCategoryColor(ExpenseCategory category) {
  switch (category) {
    case ExpenseCategory.food:
      return Colors.redAccent;
    case ExpenseCategory.transportation:
      return Colors.blueAccent;
    case ExpenseCategory.entertainment:
      return Colors.purpleAccent;
    case ExpenseCategory.utilities:
      return Colors.orangeAccent;
    case ExpenseCategory.shopping:
      return Colors.greenAccent.shade700;
    case ExpenseCategory.health:
      return Colors.pinkAccent;
    case ExpenseCategory.education:
      return Colors.tealAccent.shade700;
    case ExpenseCategory.travel:
      return Colors.amberAccent;
    case ExpenseCategory.other:
      return Colors.blueGrey;
  }
}

/// Search delegate for searching expenses
class _ExpenseSearchDelegate extends SearchDelegate<Expense?> {
  final List<Expense> expenses;
  final Function(BuildContext, Expense) onShowExpenseDetails;

  _ExpenseSearchDelegate({
    required this.expenses,
    required this.onShowExpenseDetails,
  });

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF25F5C),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.white70),
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
            showResults(context);
          },
          tooltip: AppLocalizations.tr('Clear'),
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
      tooltip: AppLocalizations.tr('Back'),
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
    if (expenses.isEmpty) {
      return const Center(
        child: LocalizedText('No expenses found'),
      );
    }

    final filteredExpenses = query.isEmpty
        ? expenses
        : expenses.where((expense) {
            final lowercaseQuery = query.toLowerCase();
            return expense.title.toLowerCase().contains(lowercaseQuery) ||
                (expense.notes?.toLowerCase().contains(lowercaseQuery) ??
                    false) ||
                expense.amount.toString().contains(lowercaseQuery) ||
                expense.category.displayName
                    .toLowerCase()
                    .contains(lowercaseQuery) ||
                expense.paymentMethod.toLowerCase().contains(lowercaseQuery);
          }).toList();

    if (filteredExpenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            LocalizedText('No expenses found for "$query"',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredExpenses.length,
      itemBuilder: (context, index) =>
          _buildSearchResultItem(context, filteredExpenses[index]),
    );
  }

  Widget _buildSearchResultItem(BuildContext context, Expense expense) {
    final theme = Theme.of(context);
    final formattedAmount = NumberFormat.currency(
      symbol: '₹', // Default currency symbol
      decimalDigits: 2,
    ).format(expense.amount);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: expense.category.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          expense.category.icon,
          color: expense.category.color,
          size: 24,
        ),
      ),
      title: LocalizedText(
        expense.title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: LocalizedText(
        expense.notes?.isNotEmpty == true
            ? expense.notes!
            : DateFormat('MMM d, yyyy').format(expense.date),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: Colors.grey[600],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          LocalizedText(
            formattedAmount,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFFF25F5C),
            ),
          ),
          LocalizedText(
            DateFormat('MMM d, yyyy').format(expense.date),
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      onTap: () {
        close(context, null);
        onShowExpenseDetails(context, expense);
      },
    );
  }
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
            color: Colors.red.shade400,
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
      // Container(
      //   padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      //   decoration: BoxDecoration(
      //     color: Colors.red.shade400.withValues(alpha:0.1),
      //     borderRadius: BorderRadius.circular(20.r),
      //   ),
      //   child: Row(
      //     mainAxisSize: MainAxisSize.min,
      //     children: [
      //       Icon(
      //         Icons.filter_list,
      //         size: 14.r,
      //         color: Colors.red.shade400,
      //       ),
      //       SizedBox(width: 4.w),
      //       LocalizedText(
      //         filterText,
      //         style: theme.textTheme.bodySmall?.copyWith(
      //           fontWeight: FontWeight.w500,
      //           color: Colors.red.shade400,
      //         ),
      //       ),
      //     ],
      //   ),
      // ),
    ],
  );
}
