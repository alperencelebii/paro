import 'package:finance_track/features/analytics/bloc/transaction_analytics_bloc.dart';
import 'package:finance_track/features/analytics/bloc/transaction_analytics_event.dart';
import 'package:finance_track/features/analytics/bloc/transaction_analytics_state.dart';
import 'package:finance_track/features/analytics/widgets/filter_bottom_sheet.dart';
import 'package:finance_track/features/analytics/widgets/sort_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:finance_track/core/localization/localization.dart';

/// Compact header that shows the Filter/Sort bar and the Applied Filters chips.
/// This reuses the analytics screen UI but can be embedded in any screen.
class TransactionsFilterControls extends StatelessWidget {
  const TransactionsFilterControls({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<TransactionAnalyticsBloc, TransactionAnalyticsState>(
      builder: (context, state) {
        if (state is! TransactionAnalyticsLoaded) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Right aligned filter/sort controls
            Padding(
              padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 16.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: 36.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Filter button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => TransactionsFilterControls
                                .showFilterBottomSheet(context),
                            borderRadius: BorderRadius.horizontal(
                              left: Radius.circular(18.r),
                            ),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w),
                              decoration: const BoxDecoration(
                                border: Border(
                                  right: BorderSide(
                                    color: Colors.black12,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.filter_list,
                                    size: 16.r,
                                    color: hasActiveFilters(state)
                                        ? theme.colorScheme.primary
                                        : Colors.black87,
                                  ),
                                  SizedBox(width: 4.w),
                                  LocalizedText('Filter',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: hasActiveFilters(state)
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: hasActiveFilters(state)
                                          ? theme.colorScheme.primary
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Sort button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () =>
                                TransactionsFilterControls.showSortDialog(
                                    context),
                            borderRadius: BorderRadius.horizontal(
                              right: Radius.circular(18.r),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12.w),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.sort,
                                    size: 16.r,
                                    color: Colors.black87,
                                  ),
                                  SizedBox(width: 4.w),
                                  LocalizedText('Sort',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
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

            // Applied filters card
            if (hasActiveFilters(state))
              Container(
                margin: EdgeInsets.only(left: 16.w, right: 16.w, top: 12.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                        left: 16.w,
                        right: 16.w,
                        top: 12.h,
                        bottom: 8.h,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.filter_alt,
                            size: 14.r,
                            color: theme.colorScheme.primary,
                          ),
                          SizedBox(width: 6.w),
                          LocalizedText('Applied Filters',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.only(left: 8.w),
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: LocalizedText('${_activeFilterCount(state)} active',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () {
                              context
                                  .read<TransactionAnalyticsBloc>()
                                  .add(const ResetFilters());
                              Future.delayed(
                                const Duration(milliseconds: 100),
                                () {
                                  if (context.mounted) {
                                    context
                                        .read<TransactionAnalyticsBloc>()
                                        .add(
                                          const LoadTransactionAnalytics(),
                                        );
                                  }
                                },
                              );
                            },
                            icon: Icon(
                              Icons.refresh,
                              size: 14.r,
                              color: theme.colorScheme.error,
                            ),
                            label: LocalizedText('Reset all',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: theme.colorScheme.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildFilterChips(context, state),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  // Public so other screens can check whether filters are active
  static bool hasActiveFilters(TransactionAnalyticsLoaded state) {
    return state.dateRange != null ||
        state.minAmount != null ||
        state.maxAmount != null ||
        (state.expenseCategories != null &&
            state.expenseCategories!.isNotEmpty) ||
        (state.incomeCategories != null &&
            state.incomeCategories!.isNotEmpty) ||
        (state.searchQuery != null && state.searchQuery!.isNotEmpty) ||
        (state.sortField != SortField.date ||
            state.sortDirection != SortDirection.descending);
  }

  static int _activeFilterCount(TransactionAnalyticsLoaded state) {
    int count = 0;
    if (state.dateRange != null) count++;
    if (state.minAmount != null || state.maxAmount != null) count++;
    if (state.expenseCategories != null && state.expenseCategories!.isNotEmpty)
      count++;
    if (state.incomeCategories != null && state.incomeCategories!.isNotEmpty)
      count++;
    if (state.searchQuery != null && state.searchQuery!.isNotEmpty) count++;
    if (state.sortField != SortField.date ||
        state.sortDirection != SortDirection.descending) count++;
    return count;
  }

  static Widget _buildFilterChips(
    BuildContext context,
    TransactionAnalyticsLoaded state,
  ) {
    final List<Widget> chips = [];

    // Date range filter
    if (state.dateRange != null) {
      final dateFormat = DateFormat('MMM d, yyyy');
      final startDate = dateFormat.format(state.dateRange!.start);
      final endDate = dateFormat.format(state.dateRange!.end);
      chips.add(_buildFilterItem(
        context: context,
        label: AppLocalizations.tr('$startDate - $endDate'),
        icon: Icons.date_range,
        onClear: () {
          context.read<TransactionAnalyticsBloc>().add(
                const ClearDateRangeFilter(),
              );
        },
      ));
    }

    // Amount range filter
    if (state.minAmount != null || state.maxAmount != null) {
      final minText =
          state.minAmount != null ? state.minAmount!.toStringAsFixed(0) : '0';
      final maxText =
          state.maxAmount != null && state.maxAmount != double.infinity
              ? state.maxAmount!.toStringAsFixed(0)
              : '∞';
      chips.add(_buildFilterItem(
        context: context,
        label: AppLocalizations.tr('₹$minText - ₹$maxText'),
        icon: Icons.attach_money,
        onClear: () {
          context.read<TransactionAnalyticsBloc>().add(
                const ClearAmountFilter(),
              );
        },
      ));
    }

    // Category filters
    if (state.expenseCategories != null &&
        state.expenseCategories!.isNotEmpty) {
      chips.add(_buildFilterItem(
        context: context,
        label: AppLocalizations.tr('${state.expenseCategories!.length} expense${state.expenseCategories!.length > 1 ? 's' : ''}'),
        icon: Icons.category,
        onClear: () {
          context.read<TransactionAnalyticsBloc>().add(
                const FilterExpensesByCategory([]),
              );
        },
      ));
    }
    if (state.incomeCategories != null && state.incomeCategories!.isNotEmpty) {
      chips.add(_buildFilterItem(
        context: context,
        label: AppLocalizations.tr('${state.incomeCategories!.length} income${state.incomeCategories!.length > 1 ? 's' : ''}'),
        icon: Icons.category,
        onClear: () {
          context.read<TransactionAnalyticsBloc>().add(
                const FilterIncomesByCategory([]),
              );
        },
      ));
    }

    // Search query filter
    if (state.searchQuery != null && state.searchQuery!.isNotEmpty) {
      chips.add(_buildFilterItem(
        context: context,
        label: state.searchQuery!,
        icon: Icons.search,
        onClear: () {
          context.read<TransactionAnalyticsBloc>().add(
                const SearchTransactions(''),
              );
        },
      ));
    }

    // Sort selection chip (visible when not default date-desc)
    String sortFieldName(SortField field) {
      switch (field) {
        case SortField.date:
          return 'Date';
        case SortField.amount:
          return 'Amount';
        case SortField.category:
          return 'Category';
        case SortField.title:
          return 'Title';
      }
    }

    if (state.sortField != SortField.date ||
        state.sortDirection != SortDirection.descending) {
      final dirArrow =
          state.sortDirection == SortDirection.ascending ? '↑' : '↓';
      final sortText = 'Sort: ${sortFieldName(state.sortField)} $dirArrow';
      chips.add(_buildFilterItem(
        context: context,
        label: sortText,
        icon: Icons.sort,
        onClear: () {
          context.read<TransactionAnalyticsBloc>().add(const SortTransactions(
                field: SortField.date,
                direction: SortDirection.descending,
              ));
        },
      ));
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Row(
          children: chips
              .map((chip) => Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: chip,
                  ))
              .toList(),
        ),
      ),
    );
  }

  static Widget _buildFilterItem({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onClear,
  }) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        elevation: 0,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14.r,
                color: theme.colorScheme.primary.withValues(alpha: 0.7),
              ),
              SizedBox(width: 6.w),
              LocalizedText(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              SizedBox(width: 4.w),
              InkWell(
                onTap: onClear,
                borderRadius: BorderRadius.circular(12.r),
                child: Container(
                  padding: EdgeInsets.all(2.r),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    size: 12.r,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      enableDrag: true,
      useSafeArea: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      builder: (context) {
        return BlocBuilder<TransactionAnalyticsBloc, TransactionAnalyticsState>(
          builder: (context, state) {
            if (state is TransactionAnalyticsLoaded) {
              return FilterBottomSheet(
                state: state,
                scrollController: ScrollController(),
                onDateRangeSelected: (dateRange) {
                  context.read<TransactionAnalyticsBloc>().add(
                        FilterTransactionsByDateRange(dateRange),
                      );
                },
                onAmountRangeSelected: (min, max) {
                  context.read<TransactionAnalyticsBloc>().add(
                        FilterTransactionsByAmountRange(
                          minAmount: min,
                          maxAmount: max,
                        ),
                      );
                },
                onExpenseCategoriesSelected: (categories) {
                  context.read<TransactionAnalyticsBloc>().add(
                        FilterExpensesByCategory(categories),
                      );
                },
                onIncomeCategoriesSelected: (categories) {
                  context.read<TransactionAnalyticsBloc>().add(
                        FilterIncomesByCategory(categories),
                      );
                },
                onResetFilters: () {
                  context
                      .read<TransactionAnalyticsBloc>()
                      .add(const ResetFilters());
                },
              );
            }
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              ),
              child: const Center(child: CircularProgressIndicator()),
            );
          },
        );
      },
    );
  }

  static void showSortDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      enableDrag: true,
      useSafeArea: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.70,
      ),
      builder: (context) {
        return BlocBuilder<TransactionAnalyticsBloc, TransactionAnalyticsState>(
          builder: (context, state) {
            if (state is TransactionAnalyticsLoaded) {
              return SortBottomSheet(
                scrollController: ScrollController(),
                currentSortField: state.sortField,
                currentSortDirection: state.sortDirection,
                onSortSelected: (field, direction) {
                  context.read<TransactionAnalyticsBloc>().add(
                        SortTransactions(field: field, direction: direction),
                      );
                },
              );
            }
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              ),
              child: const Center(child: CircularProgressIndicator()),
            );
          },
        );
      },
    );
  }
}

/// A compact Filter/Sort pill to place inline (e.g., in section header)
class TransactionsFilterPill extends StatelessWidget {
  const TransactionsFilterPill({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<TransactionAnalyticsBloc, TransactionAnalyticsState>(
      builder: (context, state) {
        if (state is! TransactionAnalyticsLoaded) {
          return const SizedBox.shrink();
        }

        return Container(
          height: 32.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Filter button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () =>
                      TransactionsFilterControls.showFilterBottomSheet(context),
                  borderRadius:
                      BorderRadius.horizontal(left: Radius.circular(18.r)),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    decoration: const BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Colors.black12, width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.filter_list,
                          size: 14.r,
                          color:
                              TransactionsFilterControls.hasActiveFilters(state)
                                  ? theme.colorScheme.primary
                                  : Colors.black87,
                        ),
                        SizedBox(width: 4.w),
                        LocalizedText('Filter',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight:
                                TransactionsFilterControls.hasActiveFilters(
                                        state)
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                            color: TransactionsFilterControls.hasActiveFilters(
                                    state)
                                ? theme.colorScheme.primary
                                : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Sort button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () =>
                      TransactionsFilterControls.showSortDialog(context),
                  borderRadius:
                      BorderRadius.horizontal(right: Radius.circular(18.r)),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    child: Row(
                      children: [
                        Icon(Icons.sort, size: 14.r, color: Colors.black87),
                        SizedBox(width: 4.w),
                        LocalizedText('Sort',
                          style:
                              TextStyle(fontSize: 11.sp, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Applied filters card (only the chips section) to place under headers
class AppliedFiltersCard extends StatelessWidget {
  const AppliedFiltersCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<TransactionAnalyticsBloc, TransactionAnalyticsState>(
      builder: (context, state) {
        if (state is! TransactionAnalyticsLoaded) {
          return const SizedBox.shrink();
        }
        if (!TransactionsFilterControls.hasActiveFilters(state)) {
          return const SizedBox.shrink();
        }
        return Container(
          margin: EdgeInsets.only(left: 16.w, right: 16.w, top: 12.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  left: 16.w,
                  right: 16.w,
                  top: 12.h,
                  bottom: 8.h,
                ),
                child: Row(
                  children: [
                    Icon(Icons.filter_alt,
                        size: 14.r, color: theme.colorScheme.primary),
                    SizedBox(width: 6.w),
                    LocalizedText('Applied Filters',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        context
                            .read<TransactionAnalyticsBloc>()
                            .add(const ResetFilters());
                        Future.delayed(const Duration(milliseconds: 100), () {
                          if (context.mounted) {
                            context.read<TransactionAnalyticsBloc>().add(
                                  const LoadTransactionAnalytics(),
                                );
                          }
                        });
                      },
                      icon: Icon(Icons.refresh,
                          size: 14.r, color: theme.colorScheme.error),
                      label: LocalizedText('Reset all',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                  ],
                ),
              ),
              TransactionsFilterControls._buildFilterChips(context, state),
            ],
          ),
        );
      },
    );
  }
}
