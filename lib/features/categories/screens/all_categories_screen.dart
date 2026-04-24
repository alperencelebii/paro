import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../core/models/currency_model.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/models/income_model.dart';
import '../../dashboard/bloc/category_analysis_bloc.dart';
import 'package:go_router/go_router.dart';
import '../widget/widgets.dart';

class AllCategoriesScreen extends StatefulWidget {
  final Currency currency;

  const AllCategoriesScreen({
    super.key,
    required this.currency,
  });

  @override
  State<AllCategoriesScreen> createState() => _AllCategoriesScreenState();
}

class _AllCategoriesScreenState extends State<AllCategoriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final String _sortOption = 'Amount (High to Low)';
  int _selectedTimeFrame = 30;

  // Filter options
  double _minAmount = 0;
  double _maxAmount = double.infinity;
  bool _showZeroAmounts = true;

  final TextEditingController _searchController = TextEditingController();

  final List<String> _timeFrameLabels = [
    'Last 7 days',
    'Last 30 days',
    'Last 3 months',
    'Last year',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Analyze Categories',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20.sp,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        automaticallyImplyLeading: false,

        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        // leading: IconButton(
        //   icon: Icon(Icons.arrow_back, size: 24.r),
        //   onPressed: () => Navigator.of(context).pop(),
        // ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(96.h),
          child: Column(
            children: [
              // Time period selector
              _buildTimeFrameSelector(theme),
              // Tab bar
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Expense'),
                  Tab(text: 'Income'),
                ],
                indicatorColor: theme.colorScheme.onPrimary,
                labelColor: theme.colorScheme.onPrimary,
                unselectedLabelColor:
                    theme.colorScheme.onPrimary.withValues(alpha: 0.7),
                labelStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
                dividerColor: Colors.transparent,
                dividerHeight: 0,
                unselectedLabelStyle: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 14.sp,
                ),
                indicatorSize: TabBarIndicatorSize.label,
                indicatorWeight: 3,
                onTap: (value) {
                  _tabController.animateTo(value);
                },
              ),
            ],
          ),
        ),
      ),
      body: BlocConsumer<CategoryAnalysisBloc, CategoryAnalysisState>(
        listener: (context, state) {
          if (state is CategoryAnalysisError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is CategoryAnalysisLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CategoryAnalysisError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48.r,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Error loading categories',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  SizedBox(height: 24.h),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<CategoryAnalysisBloc>().add(
                            const LoadCategoryAnalysis(),
                          );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is CategoryAnalysisLoaded) {
            // If time frame doesn't match selected, update it
            if (state.timeFrame != _selectedTimeFrame) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.read<CategoryAnalysisBloc>().add(
                      UpdateTimeFrame(_selectedTimeFrame),
                    );
              });
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              children: [
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Expenses tab
                      _buildCategoriesList(
                        context,
                        state.expenseCategoriesAmount,
                        state.expenseCategoriesPercentage,
                        state.totalExpenses,
                        true,
                        state,
                      ),

                      // Income tab
                      _buildCategoriesList(
                        context,
                        state.incomeCategoriesAmount,
                        state.incomeCategoriesPercentage,
                        state.totalIncomes,
                        false,
                        state,
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildTimeFrameSelector(ThemeData theme) {
    final List<int> timeFrameOptions = [7, 30, 90, 365];
    return SizedBox(
      height: 40.h,
      // padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: timeFrameOptions.length,
        padding: const EdgeInsets.only(left: 12),
        itemBuilder: (context, index) {
          final isSelected = _selectedTimeFrame == timeFrameOptions[index];
          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: InkWell(
              onTap: () {
                if (!isSelected) {
                  setState(() {
                    _selectedTimeFrame = timeFrameOptions[index];
                  });
                  context.read<CategoryAnalysisBloc>().add(
                        UpdateTimeFrame(timeFrameOptions[index]),
                      );
                }
              },
              borderRadius: BorderRadius.circular(20.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  _timeFrameLabels[index],
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoriesList(
    BuildContext context,
    Map<dynamic, double> categoriesAmount,
    Map<dynamic, double> categoriesPercentage,
    double totalAmount,
    bool isExpense,
    CategoryAnalysisLoaded state,
  ) {
    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(
      symbol: widget.currency.symbol,
      decimalDigits: 2,
    );

    // Handle empty state
    if (categoriesAmount.isEmpty) {
      return Center(
        child: Card(
          elevation: 2,
          color: theme.colorScheme.surface,
          margin: EdgeInsets.all(24.r),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(24.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isExpense ? Icons.trending_down : Icons.trending_up,
                  size: 56.r,
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                ),
                SizedBox(height: 24.h),
                Text(
                  isExpense
                      ? 'No expense categories found'
                      : 'No income categories found',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                Text(
                  'Try selecting a different time period',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Sort and filter categories
    var entries = categoriesAmount.entries.toList();

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      entries = entries.where((entry) {
        final categoryName = entry.key is String
            ? entry.key.toString()
            : isExpense
                ? (entry.key as ExpenseCategory).displayName.toLowerCase()
                : (entry.key as IncomeCategory).displayName.toLowerCase();
        return categoryName.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    // Apply amount filters
    entries = entries.where((entry) {
      final amount = entry.value;
      if (!_showZeroAmounts && amount == 0) return false;
      return amount >= _minAmount && amount <= _maxAmount;
    }).toList();

    // Apply sort
    entries.sort((a, b) {
      switch (_sortOption) {
        case 'Amount (High to Low)':
          return b.value.compareTo(a.value);
        case 'Amount (Low to High)':
          return a.value.compareTo(b.value);
        case 'Name (A to Z)':
          final nameA = a.key is String
              ? a.key.toString()
              : isExpense
                  ? (a.key as ExpenseCategory).displayName.toLowerCase()
                  : (a.key as IncomeCategory).displayName.toLowerCase();
          final nameB = b.key is String
              ? b.key.toString()
              : isExpense
                  ? (b.key as ExpenseCategory).displayName.toLowerCase()
                  : (b.key as IncomeCategory).displayName.toLowerCase();
          return nameA.compareTo(nameB);
        case 'Name (Z to A)':
          final nameA = a.key is String
              ? a.key.toString()
              : isExpense
                  ? (a.key as ExpenseCategory).displayName.toLowerCase()
                  : (a.key as IncomeCategory).displayName.toLowerCase();
          final nameB = b.key is String
              ? b.key.toString()
              : isExpense
                  ? (b.key as ExpenseCategory).displayName.toLowerCase()
                  : (b.key as IncomeCategory).displayName.toLowerCase();
          return nameB.compareTo(nameA);
        case 'Percentage (High to Low)':
          final percentA = categoriesPercentage[a.key] ?? 0;
          final percentB = categoriesPercentage[b.key] ?? 0;
          return percentB.compareTo(percentA);
        case 'Percentage (Low to High)':
          final percentA = categoriesPercentage[a.key] ?? 0;
          final percentB = categoriesPercentage[b.key] ?? 0;
          return percentA.compareTo(percentB);
        default:
          return b.value.compareTo(a.value);
      }
    });

    if (entries.isEmpty) {
      return Center(
        child: Card(
          elevation: 2,
          margin: EdgeInsets.all(24.r),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(24.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.filter_list,
                  size: 48.r,
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                ),
                SizedBox(height: 16.h),
                Text(
                  'No categories match your filters',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _searchController.clear();
                      _minAmount = 0;
                      _maxAmount = double.infinity;
                      _showZeroAmounts = true;
                    });
                  },
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear Filters'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        StatsOverviewCardWidget(
          state: state,
          isExpense: isExpense,
          selectedTimeFrame: _selectedTimeFrame,
          currency: widget.currency,
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.r),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final category = entry.key;
              final amount = entry.value;
              final percentage = categoriesPercentage[category] ?? 0.0;

              String categoryName;
              Color color;
              IconData icon;

              if (category is String) {
                categoryName = category;
                color = isExpense ? Colors.redAccent : Colors.green;
                icon = isExpense ? Icons.money_off : Icons.attach_money;
              } else if (isExpense) {
                final expenseCategory = category as ExpenseCategory;
                categoryName = expenseCategory.displayName;
                color = expenseCategory.color;
                icon = expenseCategory.icon;
              } else {
                final incomeCategory = category as IncomeCategory;
                categoryName = incomeCategory.displayName;
                color = incomeCategory.color;
                icon = incomeCategory.icon;
              }

              return Card(
                // margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                color: color.withValues(alpha: 0.08),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16.r),
                  onTap: () =>
                      _navigateToCategoryDetail(context, category, isExpense),
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Category icon
                            Container(
                              width: 44.r,
                              height: 44.r,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                icon,
                                color: Colors.white,
                                size: 22.r,
                              ),
                            ),
                            SizedBox(width: 16.w),

                            // Category name and amount
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    categoryName,
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    formatter.format(amount),
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w500,
                                      color: color,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Percentage
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12.w, vertical: 6.h),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                '${percentage.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Progress bar
                        SizedBox(height: 12.h),
                        LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: Colors.white,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 5.h,
                          borderRadius: BorderRadius.circular(2.5.r),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Add bottom padding for better scrolling experience
        SizedBox(height: 24.h),
      ],
    );
  }

  void _navigateToCategoryDetail(
    BuildContext context,
    dynamic category,
    bool isExpense,
  ) {
    // Create date range for filtering
    final dateRange = DateTimeRange(
      start: DateTime.now().subtract(Duration(days: _selectedTimeFrame)),
      end: DateTime.now(),
    );

    // Navigate using GoRouter with all necessary parameters
    context.push(
      '/category-detail',
      extra: {
        'category': category,
        'isExpense': isExpense,
        'currency': widget.currency,
        'timeFrame': _selectedTimeFrame,
        'dateRange': dateRange,
      },
    );
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging ||
        _tabController.animation!.value.round() !=
            _tabController.previousIndex) {
      setState(() {
        // Force rebuild when tab changes
      });
    }
  }
}
