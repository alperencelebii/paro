import 'package:finance_track/data/models/expense_model.dart';
import 'package:finance_track/data/models/income_model.dart';
import 'package:finance_track/features/analytics/bloc/transaction_analytics_bloc.dart';
import 'package:finance_track/features/analytics/bloc/transaction_analytics_state.dart';
import 'package:finance_track/features/analytics/screens/analytics_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:finance_track/core/utils/currency_formatter.dart';
import 'package:finance_track/core/extensions/currency_context_extension.dart';
import 'package:finance_track/core/localization/localization.dart';

/// Beautiful dialog for filtering transactions
class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({
    super.key,
    required this.state,
    required this.scrollController,
    required this.onDateRangeSelected,
    required this.onAmountRangeSelected,
    required this.onExpenseCategoriesSelected,
    required this.onIncomeCategoriesSelected,
    required this.onResetFilters,
  });

  final TransactionAnalyticsLoaded state;
  final ScrollController scrollController;
  final Function(DateTimeRange) onDateRangeSelected;
  final Function(double, double) onAmountRangeSelected;
  final Function(List<ExpenseCategory>) onExpenseCategoriesSelected;
  final Function(List<IncomeCategory>) onIncomeCategoriesSelected;
  final Function() onResetFilters;

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  // Section expansion states
  bool _isDateExpanded = true;
  bool _isAmountExpanded = false;
  bool _isCategoryExpanded = false;
  bool _showExpenseCategories = true;

  // Date filter
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  // Amount filter
  RangeValues _amountRange = const RangeValues(0, 10000);

  // Category filters
  final List<ExpenseCategory> _selectedExpenseCategories = [];
  final List<IncomeCategory> _selectedIncomeCategories = [];

  // Count of active filters
  int get _activeFilterCount {
    int count = 0;

    // Date filter active if not default 30 days
    final defaultStart = DateTime.now().subtract(const Duration(days: 30));
    if (_dateRange.start.day != defaultStart.day ||
        _dateRange.start.month != defaultStart.month ||
        _dateRange.start.year != defaultStart.year ||
        _dateRange.end.day != DateTime.now().day) {
      count++;
    }

    // Amount filter active if not default full range
    if (_amountRange.start > 0 || _amountRange.end < 10000) {
      count++;
    }

    // Category filters active
    if (_selectedExpenseCategories.isNotEmpty) count++;
    if (_selectedIncomeCategories.isNotEmpty) count++;

    return count;
  }

  @override
  void initState() {
    super.initState();

    // Get state from BLoC if needed
    final state = context.read<TransactionAnalyticsBloc>().state;
    if (state is TransactionAnalyticsLoaded) {
      // Initialize with existing filters if any
      if (state.dateRange != null) {
        _dateRange = state.dateRange!;
      }

      if (state.minAmount != null && state.maxAmount != null) {
        final min = state.minAmount!;
        // Handle case where maxAmount is infinity
        final max =
            state.maxAmount == double.infinity ? 10000.0 : state.maxAmount!;
        _amountRange = RangeValues(min, max);
      }

      if (state.expenseCategories != null) {
        _selectedExpenseCategories.addAll(state.expenseCategories!);
      }

      if (state.incomeCategories != null) {
        _selectedIncomeCategories.addAll(state.incomeCategories!);
      }
    }

    // Expand the appropriate section based on active filters
    if (_selectedExpenseCategories.isNotEmpty ||
        _selectedIncomeCategories.isNotEmpty) {
      _isCategoryExpanded = true;
      _isDateExpanded = false;
    } else if (_amountRange.start > 0 || _amountRange.end < 10000) {
      _isAmountExpanded = true;
      _isDateExpanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.height < 600;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle indicator at top of the bottom sheet
          Center(
            child: Container(
              margin: EdgeInsets.only(top: 8.h),
              width: 40.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.5.r),
              ),
            ),
          ),

          // Header with filter count badge
          Container(
            padding: EdgeInsets.only(
              left: 16.w,
              right: 16.w,
              top: isSmallScreen ? 8.h : 12.h,
              bottom: isSmallScreen ? 12.h : 16.h,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    Icon(
                      Icons.filter_list,
                      color: theme.colorScheme.primary,
                      size: 24.r,
                    ),
                    if (_activeFilterCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: EdgeInsets.all(4.r),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: LocalizedText(
                            _activeFilterCount.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: LocalizedText('Filter Transactions',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    widget.onResetFilters();
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                  ),
                  child: const LocalizedText('Reset'),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black54),
                  onPressed: () => Navigator.of(context).pop(),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.all(4.r),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isSmallScreen ? 12.r : 16.r),
              controller: widget.scrollController,
              child: Column(
                children: [
                  // Date filter section
                  _buildExpandableSection(
                    title: 'Date',
                    isExpanded: _isDateExpanded,
                    hasActiveFilter: _dateRange.start.day !=
                        DateTime.now().subtract(const Duration(days: 30)).day,
                    onToggle: () {
                      setState(() {
                        _isDateExpanded = !_isDateExpanded;
                      });
                    },
                    child: _buildDateFilter(context, isSmallScreen),
                  ),

                  Divider(height: 1, color: Colors.grey.shade200),

                  // Amount filter section
                  _buildExpandableSection(
                    title: 'Amount',
                    isExpanded: _isAmountExpanded,
                    hasActiveFilter:
                        _amountRange.start > 0 || _amountRange.end < 10000,
                    onToggle: () {
                      setState(() {
                        _isAmountExpanded = !_isAmountExpanded;
                      });
                    },
                    child: _buildAmountFilter(context, isSmallScreen),
                  ),

                  Divider(height: 1, color: Colors.grey.shade200),

                  // Category filter section
                  _buildExpandableSection(
                    title: 'Category',
                    isExpanded: _isCategoryExpanded,
                    hasActiveFilter: _selectedExpenseCategories.isNotEmpty ||
                        _selectedIncomeCategories.isNotEmpty,
                    onToggle: () {
                      setState(() {
                        _isCategoryExpanded = !_isCategoryExpanded;
                      });
                    },
                    child: _buildCategoryFilter(context, isSmallScreen),
                  ),
                ],
              ),
            ),
          ),

          // Apply button - fixed at bottom
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -4),
                ),
              ],
              border: Border(
                top: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Reset button
                OutlinedButton.icon(
                  onPressed: () {
                    // Reset all filter selections locally
                    setState(() {
                      _dateRange = DateTimeRange(
                        start:
                            DateTime.now().subtract(const Duration(days: 30)),
                        end: DateTime.now(),
                      );
                      _amountRange = const RangeValues(0, 10000);
                      _selectedExpenseCategories.clear();
                      _selectedIncomeCategories.clear();
                    });

                    // Call the reset filters function
                    widget.onResetFilters();

                    // Close the bottom sheet
                    Navigator.of(context).pop();
                  },
                  icon: Icon(
                    Icons.refresh,
                    size: 18.r,
                    color: theme.colorScheme.error,
                  ),
                  label: LocalizedText('Reset',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.error,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    side: BorderSide(
                      color: theme.colorScheme.error.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),

                // Apply button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Debug prints to track what's happening

                      if (_selectedExpenseCategories
                          .contains(ExpenseCategory.health)) {
                      } else {}

                      // Apply date range filter
                      widget.onDateRangeSelected(_dateRange);

                      // Apply amount range filter
                      widget.onAmountRangeSelected(
                        _amountRange.start,
                        _amountRange.end,
                      );

                      // Apply category filters - important to create a new list to ensure changes are detected
                      widget.onExpenseCategoriesSelected(
                        List<ExpenseCategory>.from(_selectedExpenseCategories),
                      );

                      widget.onIncomeCategoriesSelected(
                        List<IncomeCategory>.from(_selectedIncomeCategories),
                      );

                      // Close the bottom sheet after applying filters
                      Navigator.of(context).pop();
                    },
                    icon: Icon(
                      Icons.check_circle,
                      size: 18.r,
                      color: Colors.white,
                    ),
                    label: LocalizedText('Apply Filters',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        )),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required bool isExpanded,
    required bool hasActiveFilter,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header with icon and title
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Row(
              children: [
                // Title with indicator if filters are active
                LocalizedText(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight:
                        hasActiveFilter ? FontWeight.bold : FontWeight.normal,
                    color: hasActiveFilter
                        ? theme.colorScheme.primary
                        : Colors.black87,
                  ),
                ),

                if (hasActiveFilter)
                  Padding(
                    padding: EdgeInsets.only(left: 8.w),
                    child: Container(
                      width: 8.r,
                      height: 8.r,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                const Spacer(),

                // Expand/collapse icon
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.black54,
                ),
              ],
            ),
          ),
        ),

        // Expanded content
        AnimatedCrossFade(
          firstChild: const SizedBox(height: 0),
          secondChild: Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: child,
          ),
          crossFadeState:
              isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
      ],
    );
  }

  Widget _buildDateFilter(BuildContext context, bool isSmallScreen) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');

    // Show the currently selected date range nicely
    final String selectedDateRangeText;
    final now = DateTime.now();

    // Check if it matches a preset
    if (_areDateRangesEqual(
        _dateRange,
        DateTimeRange(
            start: now.subtract(const Duration(days: 7)), end: now))) {
      selectedDateRangeText = 'Last 7 days';
    } else if (_areDateRangesEqual(
        _dateRange,
        DateTimeRange(
            start: now.subtract(const Duration(days: 30)), end: now))) {
      selectedDateRangeText = 'Last 30 days';
    } else if (_areDateRangesEqual(_dateRange,
        DateTimeRange(start: DateTime(now.year, now.month, 1), end: now))) {
      selectedDateRangeText = 'This month';
    } else if (_areDateRangesEqual(
        _dateRange,
        DateTimeRange(
            start: DateTime(now.year, now.month - 1, 1),
            end: DateTime(now.year, now.month, 0)))) {
      selectedDateRangeText = 'Last month';
    } else if (_areDateRangesEqual(
        _dateRange, DateTimeRange(start: DateTime(now.year, 1, 1), end: now))) {
      selectedDateRangeText = 'This year';
    } else if (_dateRange.start.year <= 2000 && _dateRange.end.day == now.day) {
      selectedDateRangeText = 'All time';
    } else {
      // Custom date range
      selectedDateRangeText =
          '${dateFormat.format(_dateRange.start)} - ${dateFormat.format(_dateRange.end)}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current selection summary
        Container(
          margin: EdgeInsets.only(bottom: 16.h),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.date_range,
                size: 18.r,
                color: theme.colorScheme.primary,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LocalizedText('Current selection:',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    LocalizedText(
                      selectedDateRangeText,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Date range display
        Row(
          children: [
            Expanded(
              child: _buildDateCard(
                context,
                title: 'Start Date',
                date: _dateRange.start,
                onTap: () => _selectStartDate(context),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _buildDateCard(
                context,
                title: 'End Date',
                date: _dateRange.end,
                onTap: () => _selectEndDate(context),
              ),
            ),
          ],
        ),

        SizedBox(height: 16.h),

        // Preset date ranges
        LocalizedText('Quick Select',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),

        SizedBox(height: 8.h),

        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            _buildDateChip(
              context,
              label: AppLocalizations.tr('Last 7 days'),
              onTap: () {
                final newRange = DateTimeRange(
                  start: DateTime.now().subtract(const Duration(days: 7)),
                  end: DateTime.now(),
                );
                setState(() {
                  _dateRange = newRange;
                });
                widget.onDateRangeSelected(newRange);
              },
            ),
            _buildDateChip(
              context,
              label: AppLocalizations.tr('Last 30 days'),
              onTap: () {
                final newRange = DateTimeRange(
                  start: DateTime.now().subtract(const Duration(days: 30)),
                  end: DateTime.now(),
                );
                setState(() {
                  _dateRange = newRange;
                });
                widget.onDateRangeSelected(newRange);
              },
            ),
            _buildDateChip(
              context,
              label: AppLocalizations.tr('This month'),
              onTap: () {
                final now = DateTime.now();
                final firstDayOfMonth = DateTime(now.year, now.month, 1);
                final newRange = DateTimeRange(
                  start: firstDayOfMonth,
                  end: now,
                );
                setState(() {
                  _dateRange = newRange;
                });
                widget.onDateRangeSelected(newRange);
              },
            ),
            _buildDateChip(
              context,
              label: AppLocalizations.tr('Last month'),
              onTap: () {
                final now = DateTime.now();
                final firstDayOfLastMonth =
                    DateTime(now.year, now.month - 1, 1);
                final lastDayOfLastMonth = DateTime(now.year, now.month, 0);
                final newRange = DateTimeRange(
                  start: firstDayOfLastMonth,
                  end: lastDayOfLastMonth,
                );
                setState(() {
                  _dateRange = newRange;
                });
                widget.onDateRangeSelected(newRange);
              },
            ),
            _buildDateChip(
              context,
              label: AppLocalizations.tr('This year'),
              onTap: () {
                final now = DateTime.now();
                final firstDayOfYear = DateTime(now.year, 1, 1);
                final newRange = DateTimeRange(
                  start: firstDayOfYear,
                  end: now,
                );
                setState(() {
                  _dateRange = newRange;
                });
                widget.onDateRangeSelected(newRange);
              },
            ),
            _buildDateChip(
              context,
              label: AppLocalizations.tr('All time'),
              onTap: () {
                final newRange = DateTimeRange(
                  start: DateTime(2000),
                  end: DateTime.now(),
                );
                setState(() {
                  _dateRange = newRange;
                });
                widget.onDateRangeSelected(newRange);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateCard(
    BuildContext context, {
    required String title,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.all(10.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LocalizedText(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14.r,
                  color: theme.colorScheme.primary,
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: LocalizedText(
                    dateFormat.format(date),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateChip(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    // Check if this date chip matches the current date range to highlight it
    bool isSelected = false;
    final now = DateTime.now();

    if (label == 'Last 7 days') {
      final dateRange = DateTimeRange(
        start: now.subtract(const Duration(days: 7)),
        end: now,
      );
      isSelected = _areDateRangesEqual(_dateRange, dateRange);
    } else if (label == 'Last 30 days') {
      final dateRange = DateTimeRange(
        start: now.subtract(const Duration(days: 30)),
        end: now,
      );
      isSelected = _areDateRangesEqual(_dateRange, dateRange);
    } else if (label == 'This month') {
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final dateRange = DateTimeRange(
        start: firstDayOfMonth,
        end: now,
      );
      isSelected = _areDateRangesEqual(_dateRange, dateRange);
    } else if (label == 'Last month') {
      final firstDayOfLastMonth = DateTime(now.year, now.month - 1, 1);
      final lastDayOfLastMonth = DateTime(now.year, now.month, 0);
      final dateRange = DateTimeRange(
        start: firstDayOfLastMonth,
        end: lastDayOfLastMonth,
      );
      isSelected = _areDateRangesEqual(_dateRange, dateRange);
    } else if (label == 'This year') {
      final firstDayOfYear = DateTime(now.year, 1, 1);
      final dateRange = DateTimeRange(
        start: firstDayOfYear,
        end: now,
      );
      isSelected = _areDateRangesEqual(_dateRange, dateRange);
    } else if (label == 'All time') {
      final dateRange = DateTimeRange(
        start: DateTime(2000),
        end: now,
      );
      isSelected = _areDateRangesEqual(_dateRange, dateRange);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(
            color:
                isSelected ? theme.colorScheme.primary : Colors.grey.shade300,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              Padding(
                padding: EdgeInsets.only(right: 6.w),
                child: Icon(
                  Icons.check_circle,
                  size: 14.r,
                  color: Colors.white,
                ),
              ),
            LocalizedText(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to compare date ranges
  bool _areDateRangesEqual(DateTimeRange range1, DateTimeRange range2) {
    return range1.start.year == range2.start.year &&
        range1.start.month == range2.start.month &&
        range1.start.day == range2.start.day &&
        range1.end.year == range2.end.year &&
        range1.end.month == range2.end.month &&
        range1.end.day == range2.end.day;
  }

  Widget _buildAmountFilter(BuildContext context, bool isSmallScreen) {
    final theme = Theme.of(context);
    final currency = context.selectedCurrency;

    // Get a readable description of the current amount filter
    String selectedAmountText;
    if (_amountRange.start == 0 && _amountRange.end == 10000) {
      selectedAmountText = 'Any amount';
    } else if (_amountRange.start == 0 && _amountRange.end == 100) {
      selectedAmountText = 'Under ${currency.symbol}100';
    } else if (_amountRange.start == 100 && _amountRange.end == 500) {
      selectedAmountText = '${currency.symbol}100 to ${currency.symbol}500';
    } else if (_amountRange.start == 500 && _amountRange.end == 1000) {
      selectedAmountText = '${currency.symbol}500 to ${currency.symbol}1,000';
    } else if (_amountRange.start == 1000 && _amountRange.end == 10000) {
      selectedAmountText = 'Over ${currency.symbol}1,000';
    } else {
      // Custom range
      final endText = _amountRange.end >= 9999
          ? 'No limit'
          : CurrencyFormatter.format(_amountRange.end, currency);
      selectedAmountText =
          '${CurrencyFormatter.format(_amountRange.start, currency)} to $endText';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current selection summary
        Container(
          margin: EdgeInsets.only(bottom: 16.h),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              LocalizedText(
                context.currencySymbol,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LocalizedText('Current selection:',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    LocalizedText(
                      selectedAmountText,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Amount range slider
        LocalizedText('Amount Range',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),

        SizedBox(height: 8.h),

        // Amount display
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: LocalizedText(
                CurrencyFormatter.format(_amountRange.start, currency),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            LocalizedText('to',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14.sp,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: LocalizedText(
                _amountRange.end >= 9999
                    ? 'No limit'
                    : CurrencyFormatter.format(_amountRange.end, currency),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 16.h),

        // Slider
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: theme.colorScheme.primary,
            inactiveTrackColor: Colors.grey.shade300,
            thumbColor: theme.colorScheme.primary,
            overlayColor: theme.colorScheme.primary.withValues(alpha: 0.2),
            trackHeight: 4.h,
          ),
          child: RangeSlider(
            values: _amountRange,
            min: 0,
            max: 10000,
            divisions: 100,
            labels: RangeLabels(
              CurrencyFormatter.format(_amountRange.start, currency),
              _amountRange.end >= 9999
                  ? 'No limit'
                  : CurrencyFormatter.format(_amountRange.end, currency),
            ),
            onChanged: (RangeValues values) {
              setState(() {
                _amountRange = values;
              });
            },
          ),
        ),

        SizedBox(height: 16.h),

        // Preset amounts
        LocalizedText('Quick Select',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),

        SizedBox(height: 8.h),

        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            _buildAmountChip(
              context,
              label: AppLocalizations.tr('Under ${currency.symbol}100'),
              onTap: () {
                setState(() {
                  _amountRange = const RangeValues(0, 100);
                });
              },
            ),
            _buildAmountChip(
              context,
              label: AppLocalizations.tr('${currency.symbol}100-${currency.symbol}500'),
              onTap: () {
                setState(() {
                  _amountRange = const RangeValues(100, 500);
                });
              },
            ),
            _buildAmountChip(
              context,
              label: AppLocalizations.tr('${currency.symbol}500-${currency.symbol}1k'),
              onTap: () {
                setState(() {
                  _amountRange = const RangeValues(500, 1000);
                });
              },
            ),
            _buildAmountChip(
              context,
              label: AppLocalizations.tr('Over ${currency.symbol}1k'),
              onTap: () {
                setState(() {
                  _amountRange = const RangeValues(1000, 10000);
                });
              },
            ),
            _buildAmountChip(
              context,
              label: AppLocalizations.tr('Any'),
              onTap: () {
                setState(() {
                  _amountRange = const RangeValues(0, 10000);
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAmountChip(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    // Check if this amount chip matches the current amount range to highlight it
    bool isSelected = false;

    if (label.contains('Under') &&
        _amountRange.start == 0 &&
        _amountRange.end == 100) {
      isSelected = true;
    } else if (label.contains('100-500') &&
        _amountRange.start == 100 &&
        _amountRange.end == 500) {
      isSelected = true;
    } else if (label.contains('500-1k') &&
        _amountRange.start == 500 &&
        _amountRange.end == 1000) {
      isSelected = true;
    } else if (label.contains('Over') &&
        _amountRange.start == 1000 &&
        _amountRange.end == 10000) {
      isSelected = true;
    } else if (label == 'Any' &&
        _amountRange.start == 0 &&
        _amountRange.end == 10000) {
      isSelected = true;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(
            color:
                isSelected ? theme.colorScheme.primary : Colors.grey.shade300,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              Padding(
                padding: EdgeInsets.only(right: 6.w),
                child: Icon(
                  Icons.check_circle,
                  size: 14.r,
                  color: Colors.white,
                ),
              ),
            LocalizedText(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(BuildContext context, bool isSmallScreen) {
    final theme = Theme.of(context);

    // Get count summary for selected categories
    final String selectedCategoriesText;
    if (_showExpenseCategories) {
      if (_selectedExpenseCategories.isEmpty) {
        selectedCategoriesText = 'No expense categories selected';
      } else if (_selectedExpenseCategories.length ==
          ExpenseCategory.values.length) {
        selectedCategoriesText = 'All expense categories';
      } else {
        selectedCategoriesText =
            '${_selectedExpenseCategories.length} expense ${_selectedExpenseCategories.length == 1 ? 'category' : 'categories'}';
      }
    } else {
      if (_selectedIncomeCategories.isEmpty) {
        selectedCategoriesText = 'No income categories selected';
      } else if (_selectedIncomeCategories.length ==
          IncomeCategory.values.length) {
        selectedCategoriesText = 'All income categories';
      } else {
        selectedCategoriesText =
            '${_selectedIncomeCategories.length} income ${_selectedIncomeCategories.length == 1 ? 'category' : 'categories'}';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current selection summary
        Container(
          margin: EdgeInsets.only(bottom: 16.h),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.category,
                size: 18.r,
                color: theme.colorScheme.primary,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LocalizedText('Current selection:',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    LocalizedText(
                      selectedCategoriesText,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Category type toggle
        Container(
          height: 36.h,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Row(
            children: [
              // Expense tab
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _showExpenseCategories = true;
                    });
                  },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _showExpenseCategories
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: LocalizedText('Expense',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _showExpenseCategories
                            ? Colors.white
                            : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
              ),

              // Income tab
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _showExpenseCategories = false;
                    });
                  },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: !_showExpenseCategories
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: LocalizedText('Income',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: !_showExpenseCategories
                            ? Colors.white
                            : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 16.h),

        // Category selection title with selected count
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            LocalizedText('Select ${_showExpenseCategories ? 'expense' : 'income'} categories',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Select all button
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      if (_showExpenseCategories) {
                        _selectedExpenseCategories.clear();
                        // Add each category explicitly to ensure proper references
                        for (var category in ExpenseCategory.values) {
                          _selectedExpenseCategories.add(category);
                        }
                      } else {
                        _selectedIncomeCategories.clear();
                        // Add each category explicitly to ensure proper references
                        for (var category in IncomeCategory.values) {
                          _selectedIncomeCategories.add(category);
                        }
                      }
                    });
                  },
                  icon: Icon(Icons.check_box, size: 14.r),
                  label: const LocalizedText('All'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 0),
                    minimumSize: Size(0, 30.h),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    textStyle: theme.textTheme.bodySmall,
                    foregroundColor: theme.colorScheme.primary,
                  ),
                ),
                SizedBox(width: 8.w),
                // Clear all button
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      if (_showExpenseCategories) {
                        _selectedExpenseCategories.clear();
                      } else {
                        _selectedIncomeCategories.clear();
                      }
                    });
                  },
                  icon: Icon(Icons.check_box_outline_blank, size: 14.r),
                  label: const LocalizedText('None'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 0),
                    minimumSize: Size(0, 30.h),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    textStyle: theme.textTheme.bodySmall,
                    foregroundColor: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),

        SizedBox(height: 16.h),

        // Category grid with animation
        _showExpenseCategories
            ? _buildCategoryGrid(
                context,
                key: const ValueKey('expense'),
                categories: ExpenseCategory.values,
                selectedCategories: _selectedExpenseCategories,
                onToggle: (ExpenseCategory category) {
                  setState(() {
                    // Check if the category is already in the list (using string comparison for equality)
                    bool isAlreadySelected = false;
                    int indexToRemove = -1;

                    for (int i = 0;
                        i < _selectedExpenseCategories.length;
                        i++) {
                      if (_selectedExpenseCategories[i].toString() ==
                          category.toString()) {
                        isAlreadySelected = true;
                        indexToRemove = i;
                        break;
                      }
                    }

                    // Toggle the selection
                    if (isAlreadySelected) {
                      // Remove the category if it's already selected
                      if (indexToRemove >= 0) {
                        _selectedExpenseCategories.removeAt(indexToRemove);
                      }
                    } else {
                      // Add the category if it's not already selected
                      _selectedExpenseCategories.add(category);
                    }

                    // Debug the current selection
                  });
                },
              )
            : _buildCategoryGrid(
                context,
                key: const ValueKey('income'),
                categories: IncomeCategory.values,
                selectedCategories: _selectedIncomeCategories,
                onToggle: (IncomeCategory category) {
                  setState(() {
                    // Check if the category is already in the list (using string comparison for equality)
                    bool isAlreadySelected = false;
                    int indexToRemove = -1;

                    for (int i = 0; i < _selectedIncomeCategories.length; i++) {
                      if (_selectedIncomeCategories[i].toString() ==
                          category.toString()) {
                        isAlreadySelected = true;
                        indexToRemove = i;
                        break;
                      }
                    }

                    // Toggle the selection
                    if (isAlreadySelected) {
                      // Remove the category if it's already selected
                      if (indexToRemove >= 0) {
                        _selectedIncomeCategories.removeAt(indexToRemove);
                      }
                    } else {
                      // Add the category if it's not already selected
                      _selectedIncomeCategories.add(category);
                    }

                    // Debug the current selection
                  });
                },
              ),
      ],
    );
  }

  Widget _buildCategoryGrid<T>(
    BuildContext context, {
    Key? key,
    required List<T> categories,
    required List<T> selectedCategories,
    required Function(T) onToggle,
  }) {
    final theme = Theme.of(context);

    return Wrap(
      key: key,
      spacing: 8.w,
      runSpacing: 10.h,
      children: categories.map((category) {
        // Check if this category is in the selectedCategories list
        // Important: Use contains with list equality rather than direct reference equality
        bool isSelected = false;
        for (var selectedCategory in selectedCategories) {
          if (selectedCategory.toString() == category.toString()) {
            isSelected = true;
            break;
          }
        }

        final displayInfo = _getCategoryDisplayInfo(category);

        return InkWell(
          onTap: () => onToggle(category),
          borderRadius: BorderRadius.circular(30.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: isSelected ? theme.colorScheme.primary : Colors.white,
              borderRadius: BorderRadius.circular(30.r),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : Colors.grey.shade300,
                width: 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected)
                  Padding(
                    padding: EdgeInsets.only(right: 6.w),
                    child: Icon(
                      Icons.check_circle,
                      size: 14.r,
                      color: Colors.white,
                    ),
                  ),
                Icon(
                  displayInfo.icon,
                  size: 14.r,
                  color: isSelected ? Colors.white : theme.colorScheme.primary,
                ),
                SizedBox(width: 6.w),
                LocalizedText(
                  displayInfo.name,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  CategoryDisplayInfo _getCategoryDisplayInfo(dynamic category) {
    if (category is ExpenseCategory) {
      return CategoryDisplayInfo(
        name: category.displayName,
        icon: category.icon,
        color: category.color,
      );
    } else if (category is IncomeCategory) {
      return CategoryDisplayInfo(
        name: category.displayName,
        icon: category.icon,
        color: category.color,
      );
    }

    // Fallback for unexpected category type
    return CategoryDisplayInfo(
      name: 'Unknown',
      icon: Icons.help_outline,
      color: Colors.grey,
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dateRange.start,
      firstDate: DateTime(2000),
      lastDate: _dateRange.end,
    );

    if (pickedDate != null) {
      final newRange = DateTimeRange(
        start: pickedDate,
        end: _dateRange.end,
      );
      setState(() {
        _dateRange = newRange;
      });
      widget.onDateRangeSelected(newRange);
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dateRange.end,
      firstDate: _dateRange.start,
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      final newRange = DateTimeRange(
        start: _dateRange.start,
        end: pickedDate,
      );
      setState(() {
        _dateRange = newRange;
      });
      widget.onDateRangeSelected(newRange);
    }
  }
}
