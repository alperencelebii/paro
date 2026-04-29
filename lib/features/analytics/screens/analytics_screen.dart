import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:finance_track/core/localization/localization.dart';

import 'package:finance_track/features/expense_list/bloc/expense_list_state.dart';
import 'package:finance_track/features/expense_list/screens/expense_list_screen.dart';
import 'package:finance_track/features/income_list/screens/income_list_screen.dart';
import 'package:finance_track/features/monthly_summary/models/transaction_item.dart';

import '../../../core/models/currency_model.dart';
import '../../../features/expense_list/bloc/expense_list_bloc.dart';
import '../../../features/expense_list/bloc/expense_list_event.dart'
    as expense_events;
import '../../../features/transactions/utils/transaction_utils.dart';
import '../../profile/currency/bloc/currency/currency_bloc.dart';
import '../../profile/currency/bloc/currency/currency_state.dart';
import '../bloc/transaction_analytics_bloc.dart';
import '../bloc/transaction_analytics_event.dart';
import '../bloc/transaction_analytics_state.dart';
import '../cubit/analytics_cubit.dart';
import '../../../features/income_list/bloc/income_list_bloc.dart';
import '../../../features/income_list/bloc/income_list_event.dart'
    as income_events;
import '../widgets/widgets.dart';

/// Extension to add helper methods to TransactionAnalyticsLoaded
extension TransactionAnalyticsLoadedExtension on TransactionAnalyticsLoaded {
  /// Check if any filters are active
  bool get hasActiveFilters {
    return dateRange != null ||
        minAmount != null ||
        maxAmount != null ||
        (expenseCategories != null && expenseCategories!.isNotEmpty) ||
        (incomeCategories != null && incomeCategories!.isNotEmpty) ||
        (searchQuery != null && searchQuery!.isNotEmpty);
  }

  /// Count how many filters are active
  int get activeFilterCount {
    int count = 0;
    if (dateRange != null) count++;
    if (minAmount != null || maxAmount != null) count++;
    if (expenseCategories != null && expenseCategories!.isNotEmpty) count++;
    if (incomeCategories != null && incomeCategories!.isNotEmpty) count++;
    if (searchQuery != null && searchQuery!.isNotEmpty) count++;
    return count;
  }
}

/// Analytics screen showing charts and expense/income data analysis
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _hasPlayedAnimation = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Load analytics data when the screen initializes
    context.read<AnalyticsCubit>().loadAnalytics();

    // Start animation only on first load
    if (!_hasPlayedAnimation) {
      _animationController.forward();
      _hasPlayedAnimation = true;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocBuilder<CurrencyBloc, CurrencyState>(
      builder: (context, currencyState) {
        final Currency currency = currencyState is CurrencyLoaded
            ? currencyState.currency
            : const Currency(
                code: 'USD', symbol: '\$', name: 'US Dollar', flag: '');

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<AnalyticsCubit>().loadAnalytics();
              context
                  .read<TransactionAnalyticsBloc>()
                  .add(const LoadTransactionAnalytics());
              return Future<void>.value();
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildAppBar(context),
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search bar
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Padding(
                          padding: EdgeInsets.all(16.r),
                          child: SearchBarWidget(
                            controller: _searchController,
                            onSearch: (query) {
                              context
                                  .read<TransactionAnalyticsBloc>()
                                  .add(SearchTransactions(query));
                            },
                            onClear: () {
                              _searchController.clear();
                              context
                                  .read<TransactionAnalyticsBloc>()
                                  .add(const SearchTransactions(''));
                            },
                          ),
                        ),
                      ),

                      // Transaction analytics section
                      _buildTransactionAnalytics(context, currency),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 100.h,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF1D4ED8),
      // actions: [

      // ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.only(left: 20.w, bottom: 16.h),
        title: LocalizedText('Analytics',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22.sp,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1D4ED8),
                Color(0xFF1E40AF),
              ],
            ),
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
    );
  }

  Widget _buildTransactionAnalytics(BuildContext context, Currency currency) {
    return BlocBuilder<TransactionAnalyticsBloc, TransactionAnalyticsState>(
      builder: (context, state) {
        if (state is TransactionAnalyticsInitial ||
            state is TransactionAnalyticsLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state is TransactionAnalyticsError) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(24.r),
              child: SelectableText.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: AppLocalizations.tr('Error loading transaction data:\n'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    TextSpan(text: state.message),
                  ],
                ),
              ),
            ),
          );
        }

        if (state is TransactionAnalyticsLoaded) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(_fadeAnimation),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildTransactionContent(context, state, currency),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildTransactionContent(BuildContext context,
      TransactionAnalyticsLoaded state, Currency currency) {
    final formatter = NumberFormat.currency(
      symbol: currency.symbol,
      decimalDigits: 2,
    );

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Improve "Recent Transactions" header row with better filter/sort buttons
        Padding(
          padding:
              EdgeInsets.only(left: 16.w, right: 16.w, top: 24.h, bottom: 12.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Title without filter count badge (moved to filter section)
              LocalizedText('Recent Transactions',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              // Filter and sort buttons in a more cohesive container
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
                        onTap: () => _showFilterBottomSheet(context),
                        borderRadius: BorderRadius.horizontal(
                            left: Radius.circular(18.r)),
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
                                color: state.hasActiveFilters
                                    ? theme.colorScheme.primary
                                    : Colors.black87,
                              ),
                              SizedBox(width: 4.w),
                              LocalizedText('Filter',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: state.hasActiveFilters
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: state.hasActiveFilters
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
                        onTap: () => _showSortDialog(context),
                        borderRadius: BorderRadius.horizontal(
                            right: Radius.circular(18.r)),
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

        // Simplified transaction type toggle
        Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: _buildTransactionTypeToggle(context, state),
          ),
        ),

        // Active filters in a dedicated card with better organization
        if (state.hasActiveFilters)
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
                // Applied filters section header with filter count badge
                Padding(
                  padding: EdgeInsets.only(
                      left: 16.w, right: 16.w, top: 12.h, bottom: 8.h),
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
                      // Filter count badge (moved from title)
                      Container(
                        margin: EdgeInsets.only(left: 8.w),
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: LocalizedText('${state.activeFilterCount} active',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Reset all button
                      TextButton.icon(
                        onPressed: () {
                          _searchController.clear();
                          context
                              .read<TransactionAnalyticsBloc>()
                              .add(const ResetFilters());
                          Future.delayed(const Duration(milliseconds: 100), () {
                            if (mounted) {
                              // ignore: use_build_context_synchronously
                              context.read<TransactionAnalyticsBloc>().add(
                                    const LoadTransactionAnalytics(),
                                  );
                            }
                          });
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
                // Filter chips
                _buildFilterChips(context, state),
              ],
            ),
          ),

        SizedBox(height: 16.h),

        // Transaction list
        if (state.filteredTransactions.isEmpty)
          _buildEmptyState()
        else
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            // decoration: BoxDecoration(
            //   color: theme.colorScheme.surface,
            //   borderRadius: BorderRadius.circular(12.r),
            //   boxShadow: [
            //     BoxShadow(
            //       color: Colors.black.withValues(alpha:0.03),
            //       blurRadius: 6,
            //       offset: const Offset(0, 2),
            //     ),
            //   ],
            // ),
            child: Column(
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: state.showAllTransactions
                      ? state.filteredTransactions.length
                      : (state.filteredTransactions.length > 5
                          ? 5
                          : state.filteredTransactions.length),
                  itemBuilder: (context, index) {
                    final transaction = state.filteredTransactions[index];
                    return _buildTransactionTile(
                      context,
                      transaction,
                      formatter,
                      onTap: () =>
                          _navigateToTransactionDetail(context, transaction),
                    );
                  },
                ),

                // Show More/Less button
                if (state.filteredTransactions.length > 5)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: TextButton(
                      onPressed: () {
                        context.read<TransactionAnalyticsBloc>().add(
                              const ToggleShowAllTransactions(),
                            );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          LocalizedText(
                            state.showAllTransactions
                                ? 'Show Less'
                                : 'Show All (${state.filteredTransactions.length})',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 13.sp,
                            ),
                          ),
                          Icon(
                            state.showAllTransactions
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 16.r,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

        SizedBox(height: 24.h),
      ],
    );
  }

  Widget _buildTransactionTypeToggle(
      BuildContext context, TransactionAnalyticsLoaded state) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ToggleButtons(
        onPressed: (index) {
          final types = [
            TransactionType.all,
            TransactionType.expenses,
            TransactionType.incomes
          ];
          context.read<TransactionAnalyticsBloc>().add(
                ToggleTransactionType(types[index]),
              );
        },
        isSelected: [
          state.transactionType == TransactionType.all,
          state.transactionType == TransactionType.expenses,
          state.transactionType == TransactionType.incomes,
        ],
        borderRadius: BorderRadius.circular(10.r),
        fillColor: const Color(
            0xFFEEF1FF), // Light purple background for selected item
        selectedColor: theme.colorScheme.primary,
        color: Colors.grey[600],
        borderColor: Colors.transparent,
        selectedBorderColor: Colors.transparent,
        constraints: BoxConstraints.expand(
          height: 40.h,
          width: (MediaQuery.of(context).size.width - 40.w) / 3,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.all_inclusive, size: 14.r),
                const SizedBox(width: 4),
                LocalizedText('All', style: TextStyle(fontSize: 13.sp)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_downward, size: 14.r),
                const SizedBox(width: 2),
                LocalizedText('Expenses', style: TextStyle(fontSize: 12.sp)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_upward, size: 14.r),
                const SizedBox(width: 2),
                LocalizedText('Incomes', style: TextStyle(fontSize: 12.sp)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(
      BuildContext context, TransactionAnalyticsLoaded state) {
    final List<Widget> chips = [];
    final currency = context.read<CurrencyBloc>().state is CurrencyLoaded
        ? (context.read<CurrencyBloc>().state as CurrencyLoaded).currency
        : const Currency(
            code: 'USD', symbol: '\$', name: 'US Dollar', flag: '');

    // Date range filter
    if (state.dateRange != null) {
      final dateFormat = DateFormat('MMM d, yyyy');
      final startDate = dateFormat.format(state.dateRange!.start);
      final endDate = dateFormat.format(state.dateRange!.end);

      chips.add(
        _buildFilterItem(
          context: context,
          label: AppLocalizations.tr('$startDate - $endDate'),
          icon: Icons.date_range,
          onClear: () {
            context.read<TransactionAnalyticsBloc>().add(
                  FilterTransactionsByDateRange(
                    DateTimeRange(
                      start: DateTime.now().subtract(const Duration(days: 365)),
                      end: DateTime.now(),
                    ),
                  ),
                );
          },
        ),
      );
    }

    // Amount range filter
    if (state.minAmount != null || state.maxAmount != null) {
      final minText = state.minAmount != null
          ? '${currency.symbol}${state.minAmount?.toStringAsFixed(0)}'
          : '${currency.symbol}0';
      final maxText =
          state.maxAmount != null && state.maxAmount != double.infinity
              ? '${currency.symbol}${state.maxAmount?.toStringAsFixed(0)}'
              : '∞';

      chips.add(
        _buildFilterItem(
          context: context,
          label: AppLocalizations.tr('$minText - $maxText'),
          icon: Icons.attach_money,
          onClear: () {
            context.read<TransactionAnalyticsBloc>().add(
                  const FilterTransactionsByAmountRange(
                    minAmount: 0,
                    maxAmount: double.infinity,
                  ),
                );
          },
        ),
      );
    }

    // Category filters
    if (state.expenseCategories != null &&
        state.expenseCategories!.isNotEmpty) {
      chips.add(
        _buildFilterItem(
          context: context,
          label: AppLocalizations.tr('${state.expenseCategories!.length} expense${state.expenseCategories!.length > 1 ? 's' : ''}'),
          icon: Icons.category,
          onClear: () {
            context.read<TransactionAnalyticsBloc>().add(
                  const FilterExpensesByCategory([]),
                );
          },
        ),
      );
    }

    if (state.incomeCategories != null && state.incomeCategories!.isNotEmpty) {
      chips.add(
        _buildFilterItem(
          context: context,
          label: AppLocalizations.tr('${state.incomeCategories!.length} income${state.incomeCategories!.length > 1 ? 's' : ''}'),
          icon: Icons.category,
          onClear: () {
            context.read<TransactionAnalyticsBloc>().add(
                  const FilterIncomesByCategory([]),
                );
          },
        ),
      );
    }

    // Search query filter
    if (state.searchQuery != null && state.searchQuery!.isNotEmpty) {
      chips.add(
        _buildFilterItem(
          context: context,
          label: state.searchQuery!,
          icon: Icons.search,
          onClear: () {
            _searchController.clear();
            context.read<TransactionAnalyticsBloc>().add(
                  const SearchTransactions(''),
                );
          },
        ),
      );
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

  Widget _buildFilterItem({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onClear,
  }) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.only(right: 8.w),
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
        child: InkWell(
          onTap:
              null, // Make the whole item non-clickable, only the close button is clickable
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
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
                // Close button
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
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 32.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64.r,
              color: Colors.grey.withValues(alpha: 0.7),
            ),
            SizedBox(height: 16.h),
            LocalizedText('No transactions found with the current filters',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.sp,
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: () {
                _searchController.clear();
                // Reset all filters and reload transactions
                context
                    .read<TransactionAnalyticsBloc>()
                    .add(const ResetFilters());

                // Reload after a brief delay to ensure state is properly updated
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted) {
                    context.read<TransactionAnalyticsBloc>().add(
                          const LoadTransactionAnalytics(),
                        );
                  }
                });
              },
              icon: const Icon(Icons.refresh),
              label: const LocalizedText('Reset Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                elevation: 2,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show filter dialog
  void _showFilterBottomSheet(BuildContext context) {
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
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.6,
          maxChildSize: 0.9,
          expand: false,
          snap: true,
          snapSizes: const [0.7, 0.9],
          builder: (context, scrollController) {
            return BlocBuilder<TransactionAnalyticsBloc,
                TransactionAnalyticsState>(
              builder: (context, state) {
                if (state is TransactionAnalyticsLoaded) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    child: FilterBottomSheet(
                      state: state,
                      scrollController: scrollController,
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
                        context.read<TransactionAnalyticsBloc>().add(
                              const ResetFilters(),
                            );
                      },
                    ),
                  );
                }
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20.r)),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  /// Show sort dialog
  void _showSortDialog(BuildContext context) {
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
        // Remove the DraggableScrollableSheet as it's causing overflow issues
        // with bottom navigation bar
        return BlocBuilder<TransactionAnalyticsBloc, TransactionAnalyticsState>(
          builder: (context, state) {
            if (state is TransactionAnalyticsLoaded) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                child: SortBottomSheet(
                  scrollController: ScrollController(),
                  currentSortField: state.sortField,
                  currentSortDirection: state.sortDirection,
                  onSortSelected: (field, direction) {
                    context.read<TransactionAnalyticsBloc>().add(
                          SortTransactions(
                            field: field,
                            direction: direction,
                          ),
                        );
                  },
                ),
              );
            }
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              ),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          },
        );
      },
    );
  }

  void _navigateToTransactionDetail(
      BuildContext context, TransactionItem transaction) {
    // Find the original expense or income model from the analytics state
    final state = context.read<TransactionAnalyticsBloc>().state;
    if (state is TransactionAnalyticsLoaded) {
      try {
        final originalTransaction = transaction.isExpense
            ? state.allExpenses
                .firstWhereOrNull((e) => e.uuid == transaction.id)
            : state.allIncomes
                .firstWhereOrNull((i) => i.uuid == transaction.id);

        if (originalTransaction == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: LocalizedText('Transaction not found'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Show transaction details bottom sheet
        TransactionUtils.showTransactionDetails(
          context: context,
          transaction: originalTransaction,
          isExpense: transaction.isExpense,
          onEdit: () {
            // Use Navigator.pop() first to close the sheet, then navigate
            Navigator.of(context).pop();

            // Navigate to edit screen with GoRouter
            if (transaction.isExpense) {
              GoRouter.of(context).push('/expense-edit/${transaction.id}');
            } else {
              GoRouter.of(context).push('/income-edit/${transaction.id}');
            }
          },
          onDelete: () {
            // Show delete confirmation dialog
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: LocalizedText('Delete ${transaction.isExpense ? 'Expense' : 'Income'}'),
                content: LocalizedText('Are you sure you want to delete ${transaction.title}?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const LocalizedText('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (transaction.isExpense) {
                        context.read<ExpenseListBloc>().add(
                              expense_events.DeleteExpense(transaction.id),
                            );
                      } else {
                        context.read<IncomeListBloc>().add(
                              income_events.DeleteIncome(transaction.id),
                            );
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: LocalizedText('${transaction.isExpense ? 'Expense' : 'Income'} deleted'),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r)),
                          margin: EdgeInsets.only(
                              bottom: 16.h, left: 16.w, right: 16.w),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const LocalizedText('Delete'),
                  ),
                ],
              ),
            );
          },
        );
      } catch (e) {
        // Handle the case where transaction isn't found
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: LocalizedText('Error loading transaction details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildTransactionTile(
    BuildContext context,
    TransactionItem transaction,
    NumberFormat formatter, {
    required VoidCallback onTap,
  }) {
    final bool isExpense = transaction.isExpense;

    final expenseModel =
        context.read<ExpenseListBloc>().state as ExpenseListLoaded;
    final incomeModel = context.read<IncomeListBloc>().state;

    try {
      if (isExpense) {
        final expense = expenseModel.expenses
            .firstWhereOrNull((e) => e.uuid == transaction.id);
        if (expense != null) {
          return ExpenseListItemWidget(expense: expense);
        }
      } else {
        final income = incomeModel.incomes
            .firstWhereOrNull((i) => i.uuid == transaction.id);
        if (income != null) {
          return IncomeListItemWidget(income: income);
        }
      }

      // Fallback if transaction not found
      return ListTile(
        title: LocalizedText(transaction.title),
        subtitle: LocalizedText(transaction.categoryName),
        trailing: LocalizedText(
          (transaction.isExpense ? '-' : '+') +
              formatter.format(transaction.amount),
          style: TextStyle(
            color: transaction.isExpense ? Colors.red : Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: onTap,
      );
    } catch (e) {
      // Handle any errors
      return ListTile(
        title: const LocalizedText('Error loading transaction'),
        subtitle: LocalizedText(transaction.id),
        onTap: onTap,
      );
    }
  }
}

/// Helper class for category display information
class CategoryDisplayInfo {
  final String name;
  final IconData icon;
  final Color color;

  CategoryDisplayInfo({
    required this.name,
    required this.icon,
    required this.color,
  });
}
