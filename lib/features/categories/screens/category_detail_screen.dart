import 'package:finance_track/features/expense_list/bloc/expense_list_bloc.dart';
import 'package:finance_track/features/expense_list/bloc/expense_list_state.dart';
import 'package:finance_track/features/expense_list/screens/expense_list_screen.dart';
import 'package:finance_track/features/income_list/bloc/income_list_bloc.dart';
import 'package:finance_track/features/income_list/screens/income_list_screen.dart';
import 'package:finance_track/features/monthly_summary/models/transaction_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../../core/models/currency_model.dart';
import '../../../core/utils/utils.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/models/income_model.dart';
import '../../dashboard/bloc/category_analysis_bloc.dart';
import '../widget/widgets.dart';
import 'package:finance_track/core/localization/localization.dart';

class CategoryDetailScreen extends StatefulWidget {
  final dynamic category;
  final bool isExpense;
  final Currency currency;
  final DateTimeRange? dateRange;

  const CategoryDetailScreen({
    super.key,
    required this.category,
    required this.isExpense,
    required this.currency,
    this.dateRange,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTimeFrame = 30; // Default to 30 days
  late DateTimeRange _dateRange;
  late final String _categoryName;
  late final IconData _categoryIcon;
  late final Color _categoryColor;
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  bool _isFirstLoad = true;

  // Time frame options and labels
  final List<int> _timeFrameOptions = [7, 30, 90, 180, 365, 0];
  final List<String> _timeFrameLabels = [
    'Last 7 days',
    'Last 30 days',
    'Last 3 months',
    'Last 6 months',
    'Last 1 year',
    'Custom',
  ];

  // Track if we've loaded data to prevent multiple loads
  bool _hasLoadedData = false;

  // Transaction filtering properties
  String _searchQuery = '';
  double? _minAmount;
  double? _maxAmount;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _sortField;
  final bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Print debug info
    debugPrint('CategoryDetailScreen initialized with:');
    debugPrint('Category: ${widget.category}');
    debugPrint('Category type: ${widget.category.runtimeType}');
    debugPrint('IsExpense: ${widget.isExpense}');

    // Animation setup for smooth transitions
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    // Initialize date range from widget or create default
    _dateRange = widget.dateRange ??
        DateTimeRange(
          start: DateTime.now().subtract(Duration(days: _selectedTimeFrame)),
          end: DateTime.now(),
        );

    // Determine category properties safely
    _initializeCategoryProperties();

    // Initialize mock budget data for expenses
    if (widget.isExpense) {
      _initializeMockBudget();
    }
  }

  void _initializeCategoryProperties() {
    try {
      debugPrint('Initializing category properties for: ${widget.category}');
      debugPrint('Category runtime type: ${widget.category.runtimeType}');

      if (widget.isExpense) {
        if (widget.category is ExpenseCategory) {
          final category = widget.category as ExpenseCategory;
          _categoryName = category.displayName;
          _categoryIcon = category.icon;
          _categoryColor = category.color;
          debugPrint(
              'Successfully initialized ExpenseCategory: $_categoryName with color: $_categoryColor');
        } else {
          // Try to convert to ExpenseCategory if it's not already
          try {
            ExpenseCategory parsedCategory;

            if (widget.category is int) {
              int index = widget.category as int;
              if (index >= 0 && index < ExpenseCategory.values.length) {
                parsedCategory = ExpenseCategory.values[index];
              } else {
                parsedCategory = ExpenseCategory.other;
              }
            } else if (widget.category is String) {
              String categoryStr = widget.category as String;
              int index = ExpenseCategory.values.indexWhere((c) =>
                  c.toString() == 'ExpenseCategory.$categoryStr' ||
                  c.toString().contains(categoryStr));

              if (index >= 0) {
                parsedCategory = ExpenseCategory.values[index];
              } else {
                parsedCategory = ExpenseCategory.other;
              }
            } else {
              // Default to "other" category if we can't parse it
              parsedCategory = ExpenseCategory.other;
            }

            _categoryName = parsedCategory.displayName;
            _categoryIcon = parsedCategory.icon;
            _categoryColor = parsedCategory.color;
            debugPrint('Parsed ExpenseCategory: $_categoryName');
          } catch (e) {
            // Handle invalid category type for expense
            _categoryName = "Expense";
            _categoryIcon = Icons.shopping_cart;
            _categoryColor = Colors.redAccent;
            debugPrint('Error parsing expense category: $e');
          }
        }
      } else {
        if (widget.category is IncomeCategory) {
          final category = widget.category as IncomeCategory;
          _categoryName = category.displayName;
          _categoryIcon = category.icon;
          _categoryColor = category.color;
          debugPrint(
              'Successfully initialized IncomeCategory: $_categoryName with color: $_categoryColor');
        } else {
          // Try to convert to IncomeCategory if it's not already
          try {
            IncomeCategory parsedCategory;

            if (widget.category is int) {
              int index = widget.category as int;
              if (index >= 0 && index < IncomeCategory.values.length) {
                parsedCategory = IncomeCategory.values[index];
              } else {
                parsedCategory = IncomeCategory.other;
              }
            } else if (widget.category is String) {
              String categoryStr = widget.category as String;
              int index = IncomeCategory.values.indexWhere((c) =>
                  c.toString() == 'IncomeCategory.$categoryStr' ||
                  c.toString().contains(categoryStr));

              if (index >= 0) {
                parsedCategory = IncomeCategory.values[index];
              } else {
                parsedCategory = IncomeCategory.other;
              }
            } else {
              // Default to "other" category if we can't parse it
              parsedCategory = IncomeCategory.other;
            }

            _categoryName = parsedCategory.displayName;
            _categoryIcon = parsedCategory.icon;
            _categoryColor = parsedCategory.color;
            debugPrint('Parsed IncomeCategory: $_categoryName');
          } catch (e) {
            // Handle invalid category type for income
            _categoryName = "Income";
            _categoryIcon = Icons.attach_money;
            _categoryColor = Colors.green;
            debugPrint('Error parsing income category: $e');
          }
        }
      }
    } catch (e) {
      // Fallback for any errors
      _categoryName = widget.isExpense ? "Expense" : "Income";
      _categoryIcon =
          widget.isExpense ? Icons.shopping_cart : Icons.attach_money;
      _categoryColor = widget.isExpense ? Colors.redAccent : Colors.green;
      debugPrint('Error initializing category properties: $e');
    }
  }

  void _initializeMockBudget() {
    // For demo purposes, we'll set a budget for all expense categories

    // Different budget amounts by category
    if (widget.category is ExpenseCategory) {
      final category = widget.category as ExpenseCategory;
      switch (category) {
        case ExpenseCategory.food:
          break;
        case ExpenseCategory.transportation:
          break;
        case ExpenseCategory.entertainment:
          break;
        case ExpenseCategory.utilities:
          break;
        case ExpenseCategory.shopping:
          break;
        case ExpenseCategory.health:
          break;
        case ExpenseCategory.education:
          break;
        case ExpenseCategory.travel:
          break;
        case ExpenseCategory.other:
          break;
      }
    } else {
      // Default budget amount
    }
  }

  // Calculate budget metrics based on current spending
  void _updateBudgetCalculations(CategoryDetailLoaded state) {
    if (!widget.isExpense) return;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _loadCategoryData() {
    if (!mounted) return;

    try {
      // Don't check _hasLoadedData to ensure data is loaded even if the flag is already set
      _hasLoadedData = true; // Mark as loaded to prevent duplicate loads
      final bloc = context.read<CategoryAnalysisBloc>();

      debugPrint(
          'Loading category data for: ${widget.category}, isExpense: ${widget.isExpense}');

      // Process the category to ensure it's in the correct format for the bloc
      dynamic processedCategory = widget.category;

      try {
        if (widget.isExpense) {
          if (widget.category is! ExpenseCategory) {
            // Try to extract the ExpenseCategory enum
            if (widget.category is int) {
              if (widget.category >= 0 &&
                  widget.category < ExpenseCategory.values.length) {
                processedCategory = ExpenseCategory.values[widget.category];
              } else {
                processedCategory = ExpenseCategory.other;
              }
            } else if (widget.category is String) {
              try {
                final categoryIndex = ExpenseCategory.values.indexWhere((e) =>
                    e.toString() == 'ExpenseCategory.${widget.category}' ||
                    e.toString().contains(widget.category.toString()));

                if (categoryIndex >= 0) {
                  processedCategory = ExpenseCategory.values[categoryIndex];
                } else {
                  processedCategory = ExpenseCategory.other;
                }
              } catch (e) {
                debugPrint('Error extracting ExpenseCategory from string: $e');
                processedCategory = ExpenseCategory.other;
              }
            }
          }
        } else {
          // Income category processing
          if (widget.category is! IncomeCategory) {
            // Try to extract the IncomeCategory enum
            if (widget.category is int) {
              if (widget.category >= 0 &&
                  widget.category < IncomeCategory.values.length) {
                processedCategory = IncomeCategory.values[widget.category];
              } else {
                processedCategory = IncomeCategory.other;
              }
            } else if (widget.category is String) {
              try {
                final categoryIndex = IncomeCategory.values.indexWhere((e) =>
                    e.toString() == 'IncomeCategory.${widget.category}' ||
                    e.toString().contains(widget.category.toString()));

                if (categoryIndex >= 0) {
                  processedCategory = IncomeCategory.values[categoryIndex];
                } else {
                  processedCategory = IncomeCategory.other;
                }
              } catch (e) {
                debugPrint('Error extracting IncomeCategory from string: $e');
                processedCategory = IncomeCategory.other;
              }
            }
          }
        }
      } catch (e) {
        debugPrint(
            'Error processing category type: $e, using original category');
      }

      debugPrint(
          'Processed category: $processedCategory (${processedCategory.runtimeType})');

      // Make sure the bloc is in the right state first
      Future.microtask(() {
        try {
          bloc.add(
            LoadCategoryDetail(
              category: processedCategory,
              isExpense: widget.isExpense,
              timeFrame: _selectedTimeFrame,
              dateRange: _dateRange,
            ),
          );
        } catch (e) {
          debugPrint('Error adding LoadCategoryDetail event: $e');
          _hasLoadedData = false;
        }
      });
    } catch (e) {
      debugPrint('Error loading category data: $e');
      _hasLoadedData = false; // Reset on error

      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: LocalizedText('Error loading category data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _dateRange,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _categoryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _dateRange) {
      setState(() {
        _dateRange = picked;
        _selectedTimeFrame = 0; // Custom date range
        _hasLoadedData = false; // Reset the load flag for new date range
      });
      _loadCategoryData();
    }
  }

  // Helper method to get a default percentage allocation for this category
  // This would normally come from the budget settings

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: BlocConsumer<CategoryAnalysisBloc, CategoryAnalysisState>(
        listener: (context, state) {
          // Start animation when we get the correct state
          if (state is CategoryDetailLoaded &&
              _isSameCategory(state.category, widget.category) &&
              state.isExpense == widget.isExpense &&
              _isFirstLoad) {
            _animationController.forward();
            _isFirstLoad = false;
            debugPrint(
                'Category detail loaded successfully, starting animation');

            // Update budget calculations when we get new state
            if (widget.isExpense) {
              _updateBudgetCalculations(state);
            }
          }

          // Show error messages
          if (state is CategoryAnalysisError) {
            debugPrint('Category analysis error: ${state.message}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: LocalizedText('Error: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }

          // Only try loading if needed and not already loading
          if (state is! CategoryDetailLoaded &&
              state is! CategoryAnalysisLoading) {
            Future.microtask(() {
              if (mounted && !_hasLoadedData) {
                debugPrint(
                    'State is not correct detail state, loading data...');
                _loadCategoryData();
              }
            });
          }
        },
        builder: (context, state) {
          final bool hasCorrectDetailState = state is CategoryDetailLoaded &&
              _isSameCategory(state.category, widget.category) &&
              state.isExpense == widget.isExpense;

          if (!hasCorrectDetailState) {
            return _buildLoadingView();
          }

          final detailState = state;

          if (widget.isExpense) {
            _updateBudgetCalculations(detailState);
          }

          return FadeTransition(
            opacity: _fadeInAnimation,
            child: TabBarView(
              controller: _tabController,
              children: [
                // Overview Tab
                SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 24.h),
                      _buildSummaryCard(context, detailState),
                      SizedBox(height: 16.h),
                      // if (widget.isExpense) ...[
                      //   _buildBudgetTrackingCard(context, detailState),
                      //   SizedBox(height: 16.h),
                      // ],
                      _buildComparisonAnalyticsCard(context, detailState),
                      SizedBox(height: 16.h),
                      _buildTrendChartCard(context, detailState),
                      SizedBox(height: 32.h),
                    ],
                  ),
                ),
                // Transactions Tab
                CustomScrollView(
                  slivers: [
                    SliverList(
                      delegate: SliverChildListDelegate([
                        SizedBox(height: 16.h),
                        _buildTransactionList(context, state),
                        SizedBox(height: 16.h),
                      ]),
                    ),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }

  // Loading view that shows category header while data loads
  Widget _buildLoadingView() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _categoryColor,
        title: LocalizedText(
          _categoryName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _categoryIcon,
              size: 48.r,
              color: _categoryColor.withValues(alpha: 0.5),
            ),
            SizedBox(height: 16.h),
            LocalizedText('Loading $_categoryName data...',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 24.h),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      // expandedHeight: 160.h,
      // pinned: true,
      backgroundColor: _categoryColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: LocalizedText(
        _categoryName,
        style: TextStyle(
          color: Colors.white,
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.date_range, color: Colors.white, size: 20),
          onPressed: _selectDateRange,
          tooltip: AppLocalizations.tr('Select custom date range'),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(105.h),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              20.verticalSpace,

              /// month selector
              _buildTimeFrameSelecter(),
              10.verticalSpace,
              TabBarHeaderDelegate(
                tabController: _tabController,
                categoryColor: _categoryColor,
              ),
            ],
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            color: _categoryColor,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _categoryColor.withValues(alpha: 0.8),
                _categoryColor,
              ],
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -20.r,
                right: -20.r,
                child: Container(
                  width: 100.r,
                  height: 100.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: 40.h,
                left: -30.r,
                child: Container(
                  width: 80.r,
                  height: 80.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SizedBox _buildTimeFrameSelecter() {
    return SizedBox(
      height: 40.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _timeFrameOptions.length,
        padding: const EdgeInsets.only(left: 12),
        itemBuilder: (context, index) {
          final isSelected = _selectedTimeFrame == _timeFrameOptions[index];
          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: InkWell(
              onTap: () {
                if (!isSelected) {
                  setState(() {
                    _selectedTimeFrame = _timeFrameOptions[index];
                    if (_timeFrameOptions[index] > 0) {
                      final now = DateTime.now();
                      _dateRange = DateTimeRange(
                        start: now
                            .subtract(Duration(days: _timeFrameOptions[index])),
                        end: now,
                      );
                    }
                  });
                  _loadCategoryData();
                }
              },
              borderRadius: BorderRadius.circular(20.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                alignment: Alignment.center,
                child: LocalizedText(
                  _timeFrameLabels[index],
                  style: TextStyle(
                    color: isSelected ? _categoryColor : Colors.white,
                    fontSize: 13.sp,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, CategoryDetailLoaded state) {
    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(
      symbol: widget.currency.symbol,
      decimalDigits: 2,
    );

    return CategorySummaryCard(
      theme: theme,
      categoryName: _categoryName,
      amount: state.totalAmount,
      percentage: state.percentageOfTotal,
      totalAmount: state.totalAmount,
      isExpense: widget.isExpense,
      color: _categoryColor,
      icon: _categoryIcon,
      formatter: formatter,
    );
  }

  Widget _buildTrendChartCard(
      BuildContext context, CategoryDetailLoaded state) {
    return CategoryTrendChart(
      categoryColor: _categoryColor,
      currency: widget.currency,
      dateRange: _dateRange,
      periodicData: state.transactions,
    );
  }

  Widget _buildComparisonAnalyticsCard(
      BuildContext context, CategoryDetailLoaded state) {
    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(
      symbol: widget.currency.symbol,
      decimalDigits: 2,
    );

    // Generate mock data for previous period
    final currentAmount = state.totalAmount;
    final random = math.Random();
    final previousPeriodFactor =
        0.7 + random.nextDouble() * 0.6; // Between 70% and 130%
    final previousAmount = currentAmount * previousPeriodFactor;

    return CategoryComparisonCard(
      theme: theme,
      currentAmount: currentAmount,
      previousAmount: previousAmount,
      color: _categoryColor,
      formatter: formatter,
    );
  }

  Widget _buildTransactionList(
      BuildContext context, CategoryDetailLoaded state) {
    Theme.of(context);
    final filteredTransactions = _getFilteredTransactions(state.transactions);

    if (filteredTransactions.isEmpty) {
      return _buildEmptyTransactionView(context);
    }

    // Group transactions by date
    final groupedTransactions = _groupTransactionsByDate(filteredTransactions);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: groupedTransactions.length,
            itemBuilder: (context, index) {
              final date = groupedTransactions.keys.elementAt(index);
              final List<TransactionItem> transactions =
                  groupedTransactions[date]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LocalizedText(
                    formatTransactionDate(date),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  ...transactions.map((transaction) {
                    final bool isExpense = transaction.isExpense;

                    final expenseModel = context.read<ExpenseListBloc>().state
                        as ExpenseListLoaded;
                    final incomeModel = context.read<IncomeListBloc>().state;
                    if (isExpense) {
                      return ExpenseListItemWidget(
                          expense: expenseModel.expenses
                              .firstWhere((e) => e.uuid == transaction.id));
                    } else {
                      return IncomeListItemWidget(
                          income: incomeModel.incomes
                              .firstWhere((i) => i.uuid == transaction.id));
                    }
                  }).toList(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Map<DateTime, List<TransactionItem>> _groupTransactionsByDate(
      List<TransactionItem> transactions) {
    final groupedTransactions = <DateTime, List<TransactionItem>>{};

    for (var transaction in transactions) {
      final date = transaction.date;
      final dateWithoutTime = DateTime(date.year, date.month, date.day);

      if (!groupedTransactions.containsKey(dateWithoutTime)) {
        groupedTransactions[dateWithoutTime] = [];
      }
      groupedTransactions[dateWithoutTime]!.add(transaction);
    }

    // Sort dates in descending order
    final sortedKeys = groupedTransactions.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Map.fromEntries(
      sortedKeys.map((key) => MapEntry(key, groupedTransactions[key]!)),
    );
  }

  Widget _buildEmptyTransactionView(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long,
            size: 48.r,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          SizedBox(height: 16.h),
          LocalizedText(
            _hasActiveFilters()
                ? 'No transactions match your filters'
                : 'No transactions in this category',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.grey,
            ),
          ),
          if (_hasActiveFilters()) ...[
            SizedBox(height: 16.h),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _resetFilters();
                });
              },
              icon: const Icon(Icons.filter_alt_off),
              label: const LocalizedText('Clear Filters'),
            ),
          ],
        ],
      ),
    );
  }

  // Check if there are active filters
  bool _hasActiveFilters() {
    return _searchQuery.isNotEmpty ||
        _minAmount != null ||
        _maxAmount != null ||
        _startDate != null ||
        _endDate != null;
  }

  // Reset all filters
  void _resetFilters() {
    _searchQuery = '';
    _minAmount = null;
    _maxAmount = null;
    _startDate = null;
    _endDate = null;
  }

  // Get filtered transactions based on current filters
  List<TransactionItem> _getFilteredTransactions(
      List<TransactionItem> transactions) {
    if (!_hasActiveFilters() && (_sortField == null || _sortField!.isEmpty)) {
      return transactions;
    }

    // Filter transactions based on criteria
    List<TransactionItem> filtered = List.from(transactions);

    // Apply search query filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((transaction) {
        final title = widget.isExpense
            ? (transaction as Expense).title
            : (transaction as Income).title;
        final notes = widget.isExpense
            ? (transaction as Expense).notes
            : (transaction as Income).notes;

        return title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (notes != null &&
                notes.toLowerCase().contains(_searchQuery.toLowerCase()));
      }).toList();
    }

    // Apply amount filters
    if (_minAmount != null) {
      filtered = filtered.where((transaction) {
        final amount = widget.isExpense
            ? (transaction as Expense).amount
            : (transaction as Income).amount;
        return amount >= _minAmount!;
      }).toList();
    }

    if (_maxAmount != null) {
      filtered = filtered.where((transaction) {
        final amount = widget.isExpense
            ? (transaction as Expense).amount
            : (transaction as Income).amount;
        return amount <= _maxAmount!;
      }).toList();
    }

    // Apply date filters
    if (_startDate != null) {
      filtered = filtered.where((transaction) {
        final date = widget.isExpense
            ? (transaction as Expense).date
            : (transaction as Income).date;
        return date.isAfter(_startDate!) || date.isAtSameMomentAs(_startDate!);
      }).toList();
    }

    if (_endDate != null) {
      filtered = filtered.where((transaction) {
        final date = widget.isExpense
            ? (transaction as Expense).date
            : (transaction as Income).date;
        return date.isBefore(_endDate!) || date.isAtSameMomentAs(_endDate!);
      }).toList();
    }

    // Apply sorting
    if (_sortField != null && _sortField!.isNotEmpty) {
      filtered.sort((a, b) {
        dynamic valueA;
        dynamic valueB;

        switch (_sortField) {
          case 'amount':
            valueA =
                widget.isExpense ? (a as Expense).amount : (a as Income).amount;
            valueB =
                widget.isExpense ? (b as Expense).amount : (b as Income).amount;
            break;
          case 'date':
            valueA =
                widget.isExpense ? (a as Expense).date : (a as Income).date;
            valueB =
                widget.isExpense ? (b as Expense).date : (b as Income).date;
            break;
          case 'title':
            valueA =
                widget.isExpense ? (a as Expense).title : (a as Income).title;
            valueB =
                widget.isExpense ? (b as Expense).title : (b as Income).title;
            break;
          default:
            return 0;
        }

        // Handle string comparison
        if (valueA is String && valueB is String) {
          return _sortAscending
              ? valueA.compareTo(valueB)
              : valueB.compareTo(valueA);
        }

        // Handle numeric and date comparison
        if ((valueA is num && valueB is num) ||
            (valueA is DateTime && valueB is DateTime)) {
          return _sortAscending
              ? valueA.compareTo(valueB)
              : valueB.compareTo(valueA);
        }

        return 0;
      });
    }

    return filtered;
  }

  //

  // // Budget tracking card
  // Widget _buildBudgetTrackingCard(
  //     BuildContext context, CategoryDetailLoaded state) {
  //   final theme = Theme.of(context);
  //   final formatter = NumberFormat.currency(
  //     symbol: widget.currency.symbol,
  //     decimalDigits: 2,
  //   );

  //   return Container(
  //     padding: EdgeInsets.all(12.r),
  //     decoration: BoxDecoration(
  //       color: theme.cardTheme.color ?? Colors.white,
  //       borderRadius: BorderRadius.circular(24.r),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withValues(alpha:0.05),
  //           offset: const Offset(0, 4),
  //           blurRadius: 12,
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             LocalizedText(
  //               'Budget Tracking',
  //               style: theme.textTheme.titleMedium?.copyWith(
  //                 fontWeight: FontWeight.bold,
  //               ),
  //             ),
  //             GestureDetector(
  //               onTap: () {
  //                 // Show budget adjustment dialog
  //                 _showBudgetAdjustmentDialog(context);
  //               },
  //               child: Container(
  //                 padding:
  //                     EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
  //                 decoration: BoxDecoration(
  //                   color: _categoryColor.withValues(alpha:0.1),
  //                   borderRadius: BorderRadius.circular(16.r),
  //                 ),
  //                 child: Row(
  //                   children: [
  //                     Icon(
  //                       Icons.edit,
  //                       size: 16.r,
  //                       color: _categoryColor,
  //                     ),
  //                     SizedBox(width: 4.w),
  //                     LocalizedText(
  //                       'Adjust',
  //                       style: theme.textTheme.bodySmall?.copyWith(
  //                         color: _categoryColor,
  //                         fontWeight: FontWeight.bold,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //         SizedBox(height: 20.h),
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             LocalizedText(
  //               'Budget',
  //               style: theme.textTheme.bodyMedium,
  //             ),
  //             LocalizedText(
  //               formatter.format(_budgetAmount),
  //               style: theme.textTheme.titleSmall?.copyWith(
  //                 fontWeight: FontWeight.bold,
  //               ),
  //             ),
  //           ],
  //         ),
  //         SizedBox(height: 6.h),
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             LocalizedText(
  //               'Spent',
  //               style: theme.textTheme.bodyMedium,
  //             ),
  //             LocalizedText(
  //               formatter.format(state.totalAmount),
  //               style: theme.textTheme.titleSmall?.copyWith(
  //                 fontWeight: FontWeight.bold,
  //                 color: state.totalAmount > _budgetAmount ? Colors.red : null,
  //               ),
  //             ),
  //           ],
  //         ),
  //         SizedBox(height: 6.h),
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             LocalizedText(
  //               'Remaining',
  //               style: theme.textTheme.bodyMedium,
  //             ),
  //             LocalizedText(
  //               formatter.format(_budgetRemaining),
  //               style: theme.textTheme.titleSmall?.copyWith(
  //                 fontWeight: FontWeight.bold,
  //                 color: _budgetRemaining <= 0 ? Colors.red : Colors.green,
  //               ),
  //             ),
  //           ],
  //         ),
  //         SizedBox(height: 20.h),
  //         // Progress indicator
  //         Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             ClipRRect(
  //               borderRadius: BorderRadius.circular(10.r),
  //               child: LinearProgressIndicator(
  //                 value: _budgetUsedPercentage / 100,
  //                 backgroundColor: Colors.grey.withValues(alpha:0.2),
  //                 color: _getBudgetProgressColor(),
  //                 minHeight: 12.h,
  //               ),
  //             ),
  //             SizedBox(height: 6.h),
  //             LocalizedText(
  //               '${_budgetUsedPercentage.toStringAsFixed(1)}% used',
  //               style: theme.textTheme.bodySmall?.copyWith(
  //                 fontWeight: FontWeight.bold,
  //                 color: _getBudgetProgressColor(),
  //               ),
  //             ),
  //           ],
  //         ),
  //         if (_budgetUsedPercentage >= 90) ...[
  //           SizedBox(height: 16.h),
  //           Container(
  //             padding: EdgeInsets.all(12.r),
  //             decoration: BoxDecoration(
  //               color: Colors.red.withValues(alpha:0.1),
  //               borderRadius: BorderRadius.circular(12.r),
  //             ),
  //             child: Row(
  //               children: [
  //                 Icon(
  //                   Icons.warning_amber_rounded,
  //                   color: Colors.red,
  //                   size: 20.r,
  //                 ),
  //                 SizedBox(width: 8.w),
  //                 Expanded(
  //                   child: LocalizedText(
  //                     _budgetUsedPercentage >= 100
  //                         ? 'You have exceeded your budget for this category'
  //                         : 'You are close to exceeding your budget for this category',
  //                     style: theme.textTheme.bodySmall?.copyWith(
  //                       color: Colors.red,
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ],
  //         SizedBox(height: 12.h),
  //         // Daily budget info
  //         Container(
  //           padding: EdgeInsets.all(12.r),
  //           decoration: BoxDecoration(
  //             color: theme.colorScheme.primary.withValues(alpha:0.1),
  //             borderRadius: BorderRadius.circular(12.r),
  //           ),
  //           child: Row(
  //             children: [
  //               Icon(
  //                 Icons.info_outline,
  //                 color: theme.colorScheme.primary,
  //                 size: 20.r,
  //               ),
  //               SizedBox(width: 8.w),
  //               Expanded(
  //                 child: Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     LocalizedText(
  //                       'Daily budget: ${formatter.format(_budgetRemaining / math.max(state.dateRange.end.difference(DateTime.now()).inDays + 1, 1))}',
  //                       style: theme.textTheme.bodySmall?.copyWith(
  //                         fontWeight: FontWeight.bold,
  //                         color: theme.colorScheme.primary,
  //                       ),
  //                     ),
  //                     if (_budgetRemaining > 0)
  //                       LocalizedText(
  //                         'Staying within budget for the next ${state.dateRange.end.difference(DateTime.now()).inDays + 1} days',
  //                         style: theme.textTheme.bodySmall?.copyWith(
  //                           color: theme.colorScheme.primary.withValues(alpha:0.8),
  //                         ),
  //                       ),
  //                   ],
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Get appropriate color for budget progress
  // Color _getBudgetProgressColor() {
  //   if (_budgetUsedPercentage < 70) {
  //     return Colors.green;
  //   } else if (_budgetUsedPercentage < 90) {
  //     return Colors.orange;
  //   } else {
  //     return Colors.red;
  //   }
  // }

  // // Show dialog to adjust budget amount
  // Future<void> _showBudgetAdjustmentDialog(BuildContext context) async {
  //   final controller = TextEditingController(
  //     text: _budgetAmount.toStringAsFixed(2),
  //   );

  //   return showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: LocalizedText('Adjust Budget for $_categoryName'),
  //       content: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           TextField(
  //             controller: controller,
  //             keyboardType:
  //                 const TextInputType.numberWithOptions(decimal: true),
  //             decoration: InputDecoration(
  //               labelText: AppLocalizations.tr('Budget Amount'),
  //               prefixText: widget.currency.symbol,
  //               border: const OutlineInputBorder(),
  //             ),
  //           ),
  //         ],
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.of(context).pop(),
  //           child: const LocalizedText('Cancel'),
  //         ),
  //         ElevatedButton(
  //           onPressed: () {
  //             try {
  //               final newBudget = double.parse(controller.text);
  //               if (newBudget > 0) {
  //                 setState(() {
  //                   _budgetAmount = newBudget;
  //                   // Recalculate budget metrics
  //                   if (mounted) {
  //                     final state = context.read<CategoryAnalysisBloc>().state;
  //                     if (state is CategoryDetailLoaded) {
  //                       _updateBudgetCalculations(state);
  //                     }
  //                   }
  //                 });
  //               }
  //               Navigator.of(context).pop();
  //             } catch (e) {
  //               ScaffoldMessenger.of(context).showSnackBar(
  //                 const SnackBar(
  //                   content: LocalizedText('Please enter a valid amount'),
  //                   backgroundColor: Colors.red,
  //                 ),
  //               );
  //             }
  //           },
  //           child: const LocalizedText('Save'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Helper method to check if two category objects represent the same category
  bool _isSameCategory(dynamic categoryA, dynamic categoryB) {
    try {
      // Check for null values
      if (categoryA == null || categoryB == null) return false;

      // Direct equality check
      if (categoryA == categoryB) return true;

      // Handle enum comparison between ExpenseCategory or IncomeCategory
      if ((categoryA is ExpenseCategory && categoryB is ExpenseCategory) ||
          (categoryA is IncomeCategory && categoryB is IncomeCategory)) {
        return categoryA == categoryB;
      }

      // Compare indices if one is a raw index and one is an enum
      if ((categoryA is int && categoryB is ExpenseCategory) ||
          (categoryA is ExpenseCategory && categoryB is int)) {
        final int indexA = categoryA is int ? categoryA : categoryA.index;
        final int indexB = categoryB is int ? categoryB : categoryB.index;
        return indexA == indexB;
      }

      if ((categoryA is int && categoryB is IncomeCategory) ||
          (categoryA is IncomeCategory && categoryB is int)) {
        final int indexA = categoryA is int ? categoryA : categoryA.index;
        final int indexB = categoryB is int ? categoryB : categoryB.index;
        return indexA == indexB;
      }

      // For string representations, compare their string representation
      final String strA = categoryA.toString();
      final String strB = categoryB.toString();

      // For enum values like ExpenseCategory.food, just compare the raw strings
      if (strA == strB) return true;

      // If they're enum values, check if the enum names (e.g. "food") match
      final cleanA = strA.contains('.') ? strA.split('.').last : strA;
      final cleanB = strB.contains('.') ? strB.split('.').last : strB;

      // Final cleanA/cleanB comparison
      return cleanA == cleanB;
    } catch (e) {
      debugPrint('Error comparing categories: $e');
      return false;
    }
  }
}

// Sort option class to represent sorting options
class SortOption {
  final String field;
  final bool ascending;
  final String title;
  final String subtitle;
  final IconData icon;

  SortOption({
    required this.field,
    required this.ascending,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class TabBarHeaderDelegate extends StatelessWidget {
  final TabController tabController;
  final Color categoryColor;

  const TabBarHeaderDelegate({
    super.key,
    required this.tabController,
    required this.categoryColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: categoryColor,
      child: TabBar(
        controller: tabController,
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
          tabController.animateTo(value);
        },
        tabs: const [
          Tab(child: LocalizedText('Overview')),
          Tab(child: LocalizedText('Transactions')),
        ],
      ),
    );
  }
}
