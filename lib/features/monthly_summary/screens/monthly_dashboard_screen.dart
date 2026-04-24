// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';

import '../blocs/monthly_summary_cubit.dart';
import '../widgets/advanced_trend_chart.dart';
import '../../../core/models/currency_model.dart';

/// A dashboard screen displaying monthly finances with a clean, single scroll design
class MonthlyDashboardScreen extends StatefulWidget {
  static const routeName = '/monthly-dashboard';

  const MonthlyDashboardScreen({super.key});

  @override
  State<MonthlyDashboardScreen> createState() => _MonthlyDashboardScreenState();
}

class _MonthlyDashboardScreenState extends State<MonthlyDashboardScreen> {
  DateTime _selectedMonth = DateTime.now();
  DateTimeRange? _selectedDateRange;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    // Initialize date range with current month
    _selectedDateRange = DateTimeRange(
      start: DateTime(_selectedMonth.year, _selectedMonth.month, 1),
      end: DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0),
    );
    _loadData();
  }

  Future<void> _loadData() async {
    if (_selectedDateRange != null) {
      // First update the selected date range
      context
          .read<MonthlySummaryCubit>()
          .selectDateRange(_selectedDateRange!, context);
    } else {
      // Fallback to month selection if no date range is selected
      context.read<MonthlySummaryCubit>().selectMonth(_selectedMonth, context);
    }

    // Then load the data
    context.read<MonthlySummaryCubit>().loadMonthlySummary(context);
  }

  void _selectMonth(DateTime month) {
    setState(() {
      _selectedMonth = month;
      // Update date range to match selected month
      _selectedDateRange = DateTimeRange(
        start: DateTime(month.year, month.month, 1),
        end: DateTime(month.year, month.month + 1, 0),
      );
    });
    context.read<MonthlySummaryCubit>().selectMonth(month, context);
  }

  Future<void> _showMonthPicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _selectMonth(DateTime(picked.year, picked.month, 1));
      _refreshIndicatorKey.currentState?.show();
    }
  }

  Future<void> _showDateRangePicker() async {
    final now = DateTime.now();
    final lastDate = DateTime(now.year, now.month, now.day);

    // Ensure the initialRange doesn't exceed lastDate
    DateTimeRange initialRange;
    if (_selectedDateRange != null) {
      DateTime endDate = _selectedDateRange!.end;
      // If end date is after lastDate, adjust it
      if (endDate.isAfter(lastDate)) {
        endDate = lastDate;
      }
      initialRange = DateTimeRange(
        start: _selectedDateRange!.start,
        end: endDate,
      );
    } else {
      // Create default range (current month)
      final monthEnd =
          DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
      // Ensure month end doesn't exceed lastDate
      final end = monthEnd.isAfter(lastDate) ? lastDate : monthEnd;
      initialRange = DateTimeRange(
        start: DateTime(_selectedMonth.year, _selectedMonth.month, 1),
        end: end,
      );
    }

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: initialRange,
      firstDate: DateTime(2020),
      lastDate: lastDate,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        // Update selected month to match the start date of range
        _selectedMonth = DateTime(picked.start.year, picked.start.month, 1);
      });
      context.read<MonthlySummaryCubit>().selectDateRange(picked, context);
      _refreshIndicatorKey.currentState?.show();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<MonthlySummaryCubit, MonthlySummaryState>(
        builder: (context, state) {
          if (state is MonthlySummaryInitial ||
              state is MonthlySummaryLoading) {
            return _buildLoadingView();
          } else if (state is MonthlySummaryError) {
            return _buildErrorState(context, state);
          } else if (state is MonthlySummaryLoaded) {
            // Check if there's data to show
            final bool isEmpty = state.income == 0 && state.expense == 0;

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildAppBar(context, state.month, state.year),

                // Date selector
                SliverToBoxAdapter(
                  child: _buildDateSelector(context),
                ),

                // Main content
                SliverToBoxAdapter(
                  child: RefreshIndicator(
                    key: _refreshIndicatorKey,
                    onRefresh: _loadData,
                    child: isEmpty
                        ? _buildEmptyState(state.month)
                        : _buildContentView(context, state),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: const Text(
                      'Advanced Analytics',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child:
                        BlocBuilder<MonthlySummaryCubit, MonthlySummaryState>(
                      builder: (context, state) {
                        if (state is MonthlySummaryLoaded &&
                            state.dailyExpenses != null &&
                            state.dailyExpenses!.isNotEmpty) {
                          // Convert the daily spending map to FlSpots for the chart
                          final List<FlSpot> dailySpendingSpots = [];
                          final Map<int, double> dailyExpenses =
                              state.dailyExpenses!;

                          // Sort the keys to ensure correct ordering
                          final sortedDays = dailyExpenses.keys.toList()
                            ..sort();

                          // Create x-axis labels for the days of the month
                          final List<String> dayLabels = [];

                          // Convert to FlSpots for the chart
                          for (int i = 0; i < sortedDays.length; i++) {
                            final day = sortedDays[i];
                            final amount = dailyExpenses[day] ?? 0;
                            dailySpendingSpots
                                .add(FlSpot(i.toDouble(), amount));
                            dayLabels.add(day.toString());
                          }

                          // Calculate 7-day moving average if we have enough data
                          final List<FlSpot> movingAverageSpots = [];
                          if (dailySpendingSpots.length >= 7) {
                            for (int i = 6;
                                i < dailySpendingSpots.length;
                                i++) {
                              double sum = 0;
                              for (int j = i - 6; j <= i; j++) {
                                sum += dailySpendingSpots[j].y;
                              }
                              final avg = sum / 7;
                              movingAverageSpots.add(FlSpot(i.toDouble(), avg));
                            }
                          }

                          // Calculate average spending line
                          final List<FlSpot> averageSpendingLine = [];
                          if (dailySpendingSpots.isNotEmpty) {
                            double totalSpending = 0;
                            for (final spot in dailySpendingSpots) {
                              totalSpending += spot.y;
                            }
                            final avgSpending =
                                totalSpending / dailySpendingSpots.length;

                            // Create a horizontal line at the average value
                            for (int i = 0;
                                i < dailySpendingSpots.length;
                                i++) {
                              averageSpendingLine
                                  .add(FlSpot(i.toDouble(), avgSpending));
                            }
                          }

                          // Create legend items
                          final legendItems = [
                            const LegendItem(
                              label: 'Daily Spending',
                              color: Color(0xFF2196F3),
                            ),
                            if (movingAverageSpots.isNotEmpty)
                              const LegendItem(
                                label: '7-Day Trend',
                                color: Color(0xFFFF9800),
                              ),
                            const LegendItem(
                              label: 'Monthly Average',
                              color: Color(0xFF4CAF50),
                            ),
                          ];

                          // Custom tooltip formatters
                          String dailySpendingTooltip(double x, double y) {
                            final dayIndex = x.toInt();
                            if (dayIndex >= 0 && dayIndex < dayLabels.length) {
                              return 'Day ${dayLabels[dayIndex]}: ${NumberFormat.currency(symbol: '₹').format(y)}';
                            }
                            return NumberFormat.currency(symbol: '₹').format(y);
                          }

                          String movingAverageTooltip(double x, double y) {
                            return '7-Day Trend: ${NumberFormat.currency(symbol: '₹').format(y)}';
                          }

                          String averageTooltip(double x, double y) {
                            return 'Monthly Avg: ${NumberFormat.currency(symbol: '₹').format(y)}';
                          }

                          return Padding(
                            padding: EdgeInsets.all(0.r),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AdvancedTrendChart(
                                  primaryData: dailySpendingSpots,
                                  secondaryData: averageSpendingLine,
                                  tertiaryData: movingAverageSpots,
                                  currency: const Currency(
                                    name: 'INR',
                                    symbol: '₹',
                                    code: 'INR',
                                    flag: '',
                                  ),
                                  height: 300.h,
                                  horizontalInterval: 500,
                                  xLabels: dayLabels,
                                  legendItems: legendItems,
                                  primaryTooltipFormatter: dailySpendingTooltip,
                                  secondaryTooltipFormatter: averageTooltip,
                                  tertiaryTooltipFormatter:
                                      movingAverageTooltip,
                                  title: 'Daily Spending Trends',
                                  subtitle: 'Unfold Shop 2018',
                                  useDarkTheme: true,
                                ),
                                SizedBox(height: 16.h),
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [],
                                ),
                                Text(
                                  'Key Insights',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14.sp,
                                    color: Colors.black,
                                  ),
                                ),
                                12.verticalSpace,
                                _buildCompactInsightsRow(
                                  dailyExpenses,
                                  dailySpendingSpots,
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
              ],
            );
          }

          // Fallback
          return const Center(child: Text('Something went wrong'));
        },
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    final theme = Theme.of(context);

    // Format selected date for display
    final String displayDate = _selectedDateRange != null
        ? '${DateFormat('d MMM').format(_selectedDateRange!.start)} - ${DateFormat('d MMM yyyy').format(_selectedDateRange!.end)}'
        : DateFormat('MMMM yyyy').format(_selectedMonth);

    // Calculate days difference for showing in badge
    final int daysDifference = _selectedDateRange != null
        ? _selectedDateRange!.duration.inDays + 1
        : DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected Period',
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.9),
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          // SizedBox(height: 6.h),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
              side: BorderSide(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with visualization of selected period
                  Container(
                    height: 80.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withValues(alpha: 0.8),
                          theme.colorScheme.primary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Decorative circles
                        Positioned(
                          top: -15.r,
                          right: -15.r,
                          child: Container(
                            width: 60.r,
                            height: 60.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -20.r,
                          left: 20.r,
                          child: Container(
                            width: 40.r,
                            height: 40.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                        ),

                        // Content
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Row(
                            children: [
                              // Date information
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      displayDate,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 4.h),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          color: Colors.white
                                              .withValues(alpha: 0.8),
                                          size: 12.r,
                                        ),
                                        SizedBox(width: 4.w),
                                        Text(
                                          '$daysDifference ${daysDifference == 1 ? 'day' : 'days'}',
                                          style: TextStyle(
                                            color: Colors.white
                                                .withValues(alpha: 0.8),
                                            fontSize: 12.sp,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Action button
                              Material(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12.r),
                                child: InkWell(
                                  onTap: () => _showOptionsBottomSheet(context),
                                  borderRadius: BorderRadius.circular(12.r),
                                  child: Padding(
                                    padding: EdgeInsets.all(8.r),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.edit_calendar,
                                          color: Colors.white,
                                          size: 16.r,
                                        ),
                                        SizedBox(width: 6.w),
                                        Text(
                                          'Change',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13.sp,
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

                  // Quick access chips
                  Padding(
                    padding: EdgeInsets.all(16.r),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Access',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 12.h),

                        // Scrollable row of quick access chips
                        Wrap(
                          spacing: 8.w,
                          runSpacing: 8.h,
                          children: [
                            // _buildQuickAccessChip(
                            //   label: 'Today',
                            //   onTap: _selectToday,
                            //   isActive: _isTodaySelected(),
                            //   icon: Icons.today,
                            // ),
                            // _buildQuickAccessChip(
                            //   label: 'Yesterday',
                            //   onTap: _selectYesterday,
                            //   isActive: _isYesterdaySelected(),
                            //   icon: Icons.history,
                            // ),
                            // _buildQuickAccessChip(
                            //   label: 'This Week',
                            //   onTap: _selectThisWeek,
                            //   isActive: _isThisWeekSelected(),
                            //   icon: Icons.view_week,
                            // ),
                            _buildQuickAccessChip(
                              label: 'This Month',
                              onTap: _selectCurrentMonth,
                              isActive: _isCurrentMonthSelected(),
                              icon: Icons.calendar_month,
                            ),
                            _buildQuickAccessChip(
                              label: 'Last Month',
                              onTap: _selectLastMonth,
                              isActive: _isLastMonthSelected(),
                              icon: Icons.calendar_month,
                            ),
                            _buildQuickAccessChip(
                              label: 'This Year',
                              onTap: _selectThisYear,
                              isActive: _isThisYearSelected(),
                              icon: Icons.calendar_view_month,
                            ),
                            _buildQuickAccessChip(
                              label: 'Custom',
                              onTap: () => _showDateRangePicker(),
                              isActive: _isCustomRangeSelected(),
                              icon: Icons.date_range,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Refresh button
                  Container(
                    width: double.infinity,
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      border: Border(
                        top: BorderSide(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _refreshIndicatorKey.currentState?.show();
                      },
                      icon: Icon(
                        Icons.refresh,
                        size: 16.r,
                      ),
                      label: const Text('Refresh Data'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: Size.fromHeight(42.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessChip({
    required String label,
    required VoidCallback onTap,
    required bool isActive,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(right: 8.w),
      child: Material(
        color: isActive ? theme.colorScheme.primary : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20.r),
        elevation: isActive ? 0 : 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              border: Border.all(
                color: isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.primary.withValues(alpha: 0.2),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16.r,
                  color: isActive ? Colors.white : theme.colorScheme.primary,
                ),
                SizedBox(width: 6.w),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: isActive ? Colors.white : theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOptionsBottomSheet(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle and title
            Center(
              child: Padding(
                padding: EdgeInsets.only(top: 12.h),
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Row(
                children: [
                  Icon(
                    Icons.date_range,
                    color: theme.colorScheme.primary,
                    size: 24.r,
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'Select Time Period',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),

            // Options list
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Column(
                  children: [
                    // Preset periods section
                    _buildBottomSheetSection(
                      'Preset Periods',
                      [
                        _buildBottomSheetOption(
                          'Today',
                          Icons.today,
                          _selectToday,
                          _isTodaySelected(),
                        ),
                        _buildBottomSheetOption(
                          'Yesterday',
                          Icons.history,
                          _selectYesterday,
                          _isYesterdaySelected(),
                        ),
                        _buildBottomSheetOption(
                          'This Week',
                          Icons.view_week,
                          _selectThisWeek,
                          _isThisWeekSelected(),
                        ),
                        _buildBottomSheetOption(
                          'Last Week',
                          Icons.view_week_outlined,
                          _selectLastWeek,
                          _isLastWeekSelected(),
                        ),
                      ],
                    ),

                    // Monthly periods section
                    _buildBottomSheetSection(
                      'Monthly Periods',
                      [
                        _buildBottomSheetOption(
                          'This Month',
                          Icons.calendar_month,
                          _selectCurrentMonth,
                          _isCurrentMonthSelected(),
                        ),
                        _buildBottomSheetOption(
                          'Last Month',
                          Icons.calendar_month_outlined,
                          _selectLastMonth,
                          _isLastMonthSelected(),
                        ),
                        _buildBottomSheetOption(
                          'Specific Month',
                          Icons.calendar_today,
                          _showMonthPicker,
                          false,
                        ),
                      ],
                    ),

                    // Yearly and custom periods
                    _buildBottomSheetSection(
                      'Other Periods',
                      [
                        _buildBottomSheetOption(
                          'This Year',
                          Icons.calendar_view_month,
                          _selectThisYear,
                          _isThisYearSelected(),
                        ),
                        _buildBottomSheetOption(
                          'Last Year',
                          Icons.calendar_view_month_outlined,
                          _selectLastYear,
                          _isLastYearSelected(),
                        ),
                        _buildBottomSheetOption(
                          'Custom Range',
                          Icons.date_range,
                          () {
                            Navigator.pop(context);
                            _showDateRangePicker();
                          },
                          _isCustomRangeSelected(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Close button
            Padding(
              padding: EdgeInsets.all(16.r),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.surface,
                  foregroundColor: theme.colorScheme.primary,
                  minimumSize: Size.fromHeight(45.h),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    side: BorderSide(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheetSection(String title, List<Widget> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ),
        ...options,
        SizedBox(height: 8.h),
        const Divider(),
      ],
    );
  }

  Widget _buildBottomSheetOption(
    String label,
    IconData icon,
    VoidCallback onTap,
    bool isSelected,
  ) {
    final theme = Theme.of(context);

    return Material(
      color: isSelected
          ? theme.colorScheme.primary.withValues(alpha: 0.1)
          : Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20.r,
                color:
                    isSelected ? theme.colorScheme.primary : Colors.grey[700],
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color:
                        isSelected ? theme.colorScheme.primary : Colors.black87,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                  size: 20.r,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    setState(() {
      _selectedMonth = today;
      _selectedDateRange = DateTimeRange(
        start: today,
        end: today,
      );
    });
    context
        .read<MonthlySummaryCubit>()
        .selectDateRange(_selectedDateRange!, context);
    _refreshIndicatorKey.currentState?.show();
  }

  void _selectYesterday() {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    setState(() {
      _selectedMonth = yesterday;
      _selectedDateRange = DateTimeRange(
        start: yesterday,
        end: yesterday,
      );
    });
    context
        .read<MonthlySummaryCubit>()
        .selectDateRange(_selectedDateRange!, context);
    _refreshIndicatorKey.currentState?.show();
  }

  void _selectThisWeek() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Find the start of the week (Monday)
    int daysToSubtract = today.weekday - 1;
    if (daysToSubtract < 0) daysToSubtract += 7;

    final startOfWeek = today.subtract(Duration(days: daysToSubtract));

    setState(() {
      _selectedMonth = DateTime(startOfWeek.year, startOfWeek.month, 1);
      _selectedDateRange = DateTimeRange(
        start: startOfWeek,
        end: today,
      );
    });
    context
        .read<MonthlySummaryCubit>()
        .selectDateRange(_selectedDateRange!, context);
    _refreshIndicatorKey.currentState?.show();
  }

  void _selectLastWeek() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Find the start of this week (Monday)
    int daysToSubtract = today.weekday - 1;
    if (daysToSubtract < 0) daysToSubtract += 7;

    final startOfThisWeek = today.subtract(Duration(days: daysToSubtract));

    // Calculate last week's start and end
    final endOfLastWeek = startOfThisWeek.subtract(const Duration(days: 1));
    final startOfLastWeek = endOfLastWeek.subtract(const Duration(days: 6));

    setState(() {
      _selectedMonth = DateTime(startOfLastWeek.year, startOfLastWeek.month, 1);
      _selectedDateRange = DateTimeRange(
        start: startOfLastWeek,
        end: endOfLastWeek,
      );
    });
    context
        .read<MonthlySummaryCubit>()
        .selectDateRange(_selectedDateRange!, context);
    _refreshIndicatorKey.currentState?.show();
  }

  void _selectLastYear() {
    final now = DateTime.now();
    final lastYear = now.year - 1;

    setState(() {
      _selectedMonth = DateTime(lastYear, 1, 1);
      _selectedDateRange = DateTimeRange(
        start: DateTime(lastYear, 1, 1),
        end: DateTime(lastYear, 12, 31),
      );
    });
    context
        .read<MonthlySummaryCubit>()
        .selectDateRange(_selectedDateRange!, context);
    _refreshIndicatorKey.currentState?.show();
  }

  bool _isTodaySelected() {
    if (_selectedDateRange == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _selectedDateRange!.start.year == today.year &&
        _selectedDateRange!.start.month == today.month &&
        _selectedDateRange!.start.day == today.day &&
        _selectedDateRange!.end.year == today.year &&
        _selectedDateRange!.end.month == today.month &&
        _selectedDateRange!.end.day == today.day;
  }

  bool _isYesterdaySelected() {
    if (_selectedDateRange == null) return false;

    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    return _selectedDateRange!.start.year == yesterday.year &&
        _selectedDateRange!.start.month == yesterday.month &&
        _selectedDateRange!.start.day == yesterday.day &&
        _selectedDateRange!.end.year == yesterday.year &&
        _selectedDateRange!.end.month == yesterday.month &&
        _selectedDateRange!.end.day == yesterday.day;
  }

  bool _isThisWeekSelected() {
    if (_selectedDateRange == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Find the start of the week (Monday)
    int daysToSubtract = today.weekday - 1;
    if (daysToSubtract < 0) daysToSubtract += 7;

    final startOfWeek = today.subtract(Duration(days: daysToSubtract));

    return _selectedDateRange!.start.year == startOfWeek.year &&
        _selectedDateRange!.start.month == startOfWeek.month &&
        _selectedDateRange!.start.day == startOfWeek.day &&
        _selectedDateRange!.end.year == today.year &&
        _selectedDateRange!.end.month == today.month &&
        _selectedDateRange!.end.day == today.day;
  }

  bool _isLastWeekSelected() {
    if (_selectedDateRange == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Find the start of this week (Monday)
    int daysToSubtract = today.weekday - 1;
    if (daysToSubtract < 0) daysToSubtract += 7;

    final startOfThisWeek = today.subtract(Duration(days: daysToSubtract));

    // Calculate last week's start and end
    final endOfLastWeek = startOfThisWeek.subtract(const Duration(days: 1));
    final startOfLastWeek = endOfLastWeek.subtract(const Duration(days: 6));

    return _selectedDateRange!.start.year == startOfLastWeek.year &&
        _selectedDateRange!.start.month == startOfLastWeek.month &&
        _selectedDateRange!.start.day == startOfLastWeek.day &&
        _selectedDateRange!.end.year == endOfLastWeek.year &&
        _selectedDateRange!.end.month == endOfLastWeek.month &&
        _selectedDateRange!.end.day == endOfLastWeek.day;
  }

  bool _isCustomRangeSelected() {
    if (_selectedDateRange == null) return false;

    return !_isTodaySelected() &&
        !_isYesterdaySelected() &&
        !_isThisWeekSelected() &&
        !_isLastWeekSelected() &&
        !_isCurrentMonthSelected() &&
        !_isLastMonthSelected() &&
        !_isThisYearSelected() &&
        !_isLastYearSelected();
  }

  Widget _buildLoadingView() {
    return CustomScrollView(
      slivers: [
        _buildAppBar(context, 'Loading...', ''),
        const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, String month, String year) {
    final theme = Theme.of(context);

    return SliverAppBar(
      expandedHeight: 120.h,
      pinned: true,
      stretch: true,
      centerTitle: false,
      backgroundColor: theme.colorScheme.primary,
      leading: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(Icons.arrow_back, color: Colors.white),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Monthly Summary',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Decorative elements
            Positioned(
              top: -20.r,
              right: -15.r,
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
              bottom: -30.r,
              left: -15.r,
              child: Container(
                width: 120.r,
                height: 120.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, MonthlySummaryError state) {
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        _buildAppBar(context, 'Error', ''),
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  color: theme.colorScheme.error,
                  size: 48.r,
                ),
                SizedBox(height: 16.h),
                Text(
                  'Error Loading Summary',
                  style: theme.textTheme.titleLarge,
                ),
                SizedBox(height: 8.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: SelectableText.rich(
                    TextSpan(
                      text: state.message,
                      style: TextStyle(
                        color: theme.colorScheme.error,
                      ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 24.h),
                ElevatedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    padding:
                        EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: const Duration(milliseconds: 400)),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String month) {
    return SizedBox(
      height: MediaQuery.of(context).size.height - 120.h,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              color: Colors.grey.withValues(alpha: 0.5),
              size: 72.r,
            ),
            SizedBox(height: 16.h),
            Text(
              'No transactions for $month',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Add income and expenses to see your summary',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14.sp,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to transaction entry screen
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Transaction'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 400));
  }

  Widget _buildContentView(BuildContext context, MonthlySummaryLoaded state) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Financial overview card
          _buildFinancialOverviewCard(state),

          // SizedBox(height: 16.h),

          // // Budget progress tracking card
          // _buildBudgetProgressCard(state),

          SizedBox(height: 16.h),

          // Category breakdown card
          _buildCategoryBreakdownCard(state),

          // Extra space at bottom for better scrolling
          SizedBox(height: 24.h),
        ],
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 400));
  }

  Widget _buildFinancialOverviewCard(MonthlySummaryLoaded state) {
    final theme = Theme.of(context);
    final savingsRate = state.income > 0
        ? ((state.income - state.expense) / state.income * 100)
        : 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.8),
              theme.colorScheme.primary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Financial Overview',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        savingsRate >= 20
                            ? Icons.thumb_up
                            : Icons.thumb_up_off_alt,
                        color: Colors.white,
                        size: 14.r,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '${savingsRate.toStringAsFixed(1)}% saved',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            LayoutBuilder(builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 32.w) / 3;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _buildFinancialOverviewItem(
                      context,
                      'Income',
                      state.income,
                      Icons.arrow_upward,
                      Colors.green.shade200,
                      state.currency,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  SizedBox(
                    width: itemWidth,
                    child: _buildFinancialOverviewItem(
                      context,
                      'Expense',
                      state.expense,
                      Icons.arrow_downward,
                      Colors.red.shade200,
                      state.currency,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  SizedBox(
                    width: itemWidth,
                    child: _buildFinancialOverviewItem(
                      context,
                      'Balance',
                      state.balance,
                      state.balance >= 0
                          ? Icons.account_balance_wallet
                          : Icons.warning,
                      state.balance >= 0
                          ? Colors.blue.shade200
                          : Colors.orange.shade200,
                      state.currency,
                    ),
                  ),
                ],
              );
            }),
            SizedBox(height: 16.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: LinearProgressIndicator(
                value: state.income > 0
                    ? (state.expense / state.income).clamp(0.0, 1.0)
                    : 0.0,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                color: _getProgressColor(
                    state.expense / (state.income > 0 ? state.income : 1)),
                minHeight: 8.h,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              state.income > 0
                  ? 'You\'ve spent ${((state.expense / state.income) * 100).toStringAsFixed(1)}% of your income'
                  : 'No income recorded for this period',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12.sp,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialOverviewItem(
    BuildContext context,
    String label,
    double amount,
    IconData icon,
    Color iconColor,
    Currency currency,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 16.r,
              ),
            ),
            SizedBox(width: 4.w),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14.sp,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            NumberFormat.currency(
              symbol: currency.symbol,
              decimalDigits: 0,
            ).format(amount),
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Color _getProgressColor(double ratio) {
    if (ratio <= 0.5) return Colors.green.shade300;
    if (ratio <= 0.75) return Colors.orange.shade300;
    return Colors.red.shade300;
  }

  Widget _buildCategoryBreakdownCard(MonthlySummaryLoaded state) {
    final theme = Theme.of(context);

    // Mock category data - in a real app, you'd get this from your state
    final expenseCategories = [
      {
        'name': 'Food',
        'amount': 8500.0,
        'color': Colors.orange,
        'icon': Icons.restaurant
      },
      {
        'name': 'Transport',
        'amount': 4200.0,
        'color': Colors.blue,
        'icon': Icons.directions_car
      },
      {
        'name': 'Entertainment',
        'amount': 3600.0,
        'color': Colors.purple,
        'icon': Icons.movie
      },
      {
        'name': 'Shopping',
        'amount': 7300.0,
        'color': Colors.green,
        'icon': Icons.shopping_bag
      },
      {
        'name': 'Bills',
        'amount': 5200.0,
        'color': Colors.red,
        'icon': Icons.receipt
      },
    ];

    final totalExpense = expenseCategories.fold(
        0.0, (sum, item) => sum + (item['amount'] as double));

    // Sort categories by amount in descending order
    final sortedCategories = List.from(expenseCategories)
      ..sort(
          (a, b) => (b['amount'] as double).compareTo(a['amount'] as double));
    final topCategories = sortedCategories.take(4).toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient: LinearGradient(
            colors: [
              Colors.teal.shade400,
              Colors.teal.shade700,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with chart
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expense Breakdown',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Pie chart and legend in a row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Pie chart with shadow
                      Container(
                        width: 120.r,
                        height: 120.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: Stack(
                          children: [
                            AspectRatio(
                              aspectRatio: 1,
                              child: PieChart(
                                PieChartData(
                                  sections: expenseCategories.map((category) {
                                    return PieChartSectionData(
                                      color: category['color'] as Color,
                                      value: category['amount'] as double,
                                      title: '',
                                      radius: 52.r,
                                      titleStyle: const TextStyle(
                                        fontSize: 0,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      borderSide: const BorderSide(
                                        width: 1.5,
                                        color: Colors.white,
                                      ),
                                    );
                                  }).toList(),
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 26.r,
                                ),
                              ),
                            ),
                            Center(
                              child: Container(
                                padding: EdgeInsets.all(8.r),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    )
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Total',
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        NumberFormat.compact(
                                          locale: 'en_IN',
                                        ).format(totalExpense),
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.teal.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 24.w),

                      // Legend
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: expenseCategories
                              .take(3) // Show top 3 categories
                              .map((category) {
                            final percent = (category['amount'] as double) /
                                totalExpense *
                                100;
                            return Padding(
                              padding: EdgeInsets.only(bottom: 12.h),
                              child: Row(
                                children: [
                                  Container(
                                    width: 16.r,
                                    height: 16.r,
                                    decoration: BoxDecoration(
                                      color: category['color'] as Color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.05),
                                          blurRadius: 2,
                                          spreadRadius: 1,
                                        )
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          category['name'] as String,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 2.h),
                                        Text(
                                          '${percent.toStringAsFixed(1)}% of total',
                                          style: TextStyle(
                                            color: Colors.white
                                                .withValues(alpha: 0.7),
                                            fontSize: 11.sp,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Category list in white section
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16.r),
                  bottomRight: Radius.circular(16.r),
                ),
              ),
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 12.h, left: 4.w),
                    child: Text(
                      'Top Spending Categories',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),

                  // Top expense categories
                  ...topCategories.map((category) {
                    final percent =
                        (category['amount'] as double) / totalExpense * 100;
                    return Padding(
                      padding: EdgeInsets.only(bottom: 16.h),
                      child: Row(
                        children: [
                          // Icon in colored circle
                          Container(
                            padding: EdgeInsets.all(10.r),
                            decoration: BoxDecoration(
                              color: (category['color'] as Color)
                                  .withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: (category['color'] as Color)
                                    .withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              category['icon'] as IconData,
                              color: category['color'] as Color,
                              size: 18.r,
                            ),
                          ),
                          SizedBox(width: 12.w),

                          // Category details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      category['name'] as String,
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      NumberFormat.currency(
                                        symbol: state.currency.symbol,
                                        decimalDigits: 0,
                                      ).format(category['amount']),
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4.h),

                                // Progress bar showing percentage of total
                                Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(4.r),
                                        child: LinearProgressIndicator(
                                          value: percent / 100,
                                          backgroundColor: Colors.grey[200],
                                          color: category['color'] as Color,
                                          minHeight: 5.h,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      '${percent.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w500,
                                        color: category['color'] as Color,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  // View All button
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Navigate to detailed category breakdown
                      },
                      icon: Icon(
                        Icons.pie_chart,
                        size: 16.r,
                        color: theme.colorScheme.primary,
                      ),
                      label: Text(
                        'View All Categories',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        side: BorderSide(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.5)),
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 10.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
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
    );
  }

  Widget _buildCompactInsightsRow(
      Map<int, double> dailyExpenses, List<FlSpot> dailySpendingSpots) {
    return Container(
      // margin: EdgeInsets.symmetric(horizontal: 12.w),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildCompactInsight(
                icon: Icons.arrow_upward,
                label: 'Highest',
                value: _getHighestSpendingDay(dailyExpenses),
                color: Colors.redAccent,
                flex: 1,
              ),
              SizedBox(width: 16.w),
              _buildCompactInsight(
                icon: Icons.arrow_downward,
                label: 'Lowest',
                value: _getLowestSpendingDay(dailyExpenses),
                color: Colors.greenAccent,
                flex: 1,
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildCompactInsight(
            icon: Icons.autorenew,
            label: 'Trend',
            value: _getSpendingTrend(dailySpendingSpots),
            color: Colors.blueAccent,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInsight({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    int flex = 0,
    bool isFullWidth = false,
  }) {
    final valueText = value.contains(':') ? value.split(':')[1].trim() : value;
    final dayText =
        value.contains(':') ? 'Day ${value.split(':')[0].split(' ')[1]}' : '';

    return Expanded(
      flex: flex,
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 16.sp,
                  color: color,
                ),
                SizedBox(width: 6.w),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12.sp,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            if (dayText.isNotEmpty)
              Text(
                dayText,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
            Text(
              valueText,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color.withAlpha(220),
                fontSize: 14.sp,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  String _getHighestSpendingDay(Map<int, double> dailyExpenses) {
    if (dailyExpenses.isEmpty) return 'N/A';

    int highestDay = dailyExpenses.keys.first;
    double highestAmount = dailyExpenses.values.first;

    dailyExpenses.forEach((day, amount) {
      if (amount > highestAmount) {
        highestAmount = amount;
        highestDay = day;
      }
    });

    return 'Day $highestDay: ${NumberFormat.currency(symbol: '₹').format(highestAmount)}';
  }

  String _getLowestSpendingDay(Map<int, double> dailyExpenses) {
    if (dailyExpenses.isEmpty) return 'N/A';

    int lowestDay = dailyExpenses.keys.first;
    double lowestAmount = dailyExpenses.values.first;

    dailyExpenses.forEach((day, amount) {
      if (amount < lowestAmount && amount > 0) {
        lowestAmount = amount;
        lowestDay = day;
      }
    });

    return 'Day $lowestDay: ${NumberFormat.currency(symbol: '₹').format(lowestAmount)}';
  }

  String _getSpendingTrend(List<FlSpot> dailySpendingSpots) {
    if (dailySpendingSpots.length < 5) return 'Insufficient Data';

    // Get the last 5 days to determine the trend
    final last5Days = dailySpendingSpots.sublist(
      dailySpendingSpots.length - 5 > 0 ? dailySpendingSpots.length - 5 : 0,
    );

    int increasing = 0;
    int decreasing = 0;

    for (int i = 1; i < last5Days.length; i++) {
      if (last5Days[i].y > last5Days[i - 1].y) {
        increasing++;
      } else if (last5Days[i].y < last5Days[i - 1].y) {
        decreasing++;
      }
    }

    if (increasing > decreasing) {
      return 'Increasing';
    } else if (decreasing > increasing) {
      return 'Decreasing';
    } else {
      return 'Stable';
    }
  }

  void _selectCurrentMonth() {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0).day;

    setState(() {
      _selectedMonth = currentMonth;
      _selectedDateRange = DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: DateTime(now.year, now.month, lastDay),
      );
    });
    context
        .read<MonthlySummaryCubit>()
        .selectDateRange(_selectedDateRange!, context);
    _refreshIndicatorKey.currentState?.show();
  }

  void _selectLastMonth() {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1, 1);
    final lastDay = DateTime(now.year, now.month, 0).day;

    setState(() {
      _selectedMonth = lastMonth;
      _selectedDateRange = DateTimeRange(
        start: DateTime(lastMonth.year, lastMonth.month, 1),
        end: DateTime(lastMonth.year, lastMonth.month, lastDay),
      );
    });
    context
        .read<MonthlySummaryCubit>()
        .selectDateRange(_selectedDateRange!, context);
    _refreshIndicatorKey.currentState?.show();
  }

  void _selectThisYear() {
    final now = DateTime.now();
    setState(() {
      _selectedMonth = DateTime(now.year, 1, 1);
      _selectedDateRange = DateTimeRange(
        start: DateTime(now.year, 1, 1),
        end: DateTime(now.year, 12, 31),
      );
    });
    context
        .read<MonthlySummaryCubit>()
        .selectDateRange(_selectedDateRange!, context);
    _refreshIndicatorKey.currentState?.show();
  }

  bool _isCurrentMonthSelected() {
    if (_selectedDateRange == null) return false;

    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;

    return _selectedDateRange!.start.year == now.year &&
        _selectedDateRange!.start.month == now.month &&
        _selectedDateRange!.start.day == 1 &&
        _selectedDateRange!.end.year == now.year &&
        _selectedDateRange!.end.month == now.month &&
        _selectedDateRange!.end.day == lastDay;
  }

  bool _isLastMonthSelected() {
    if (_selectedDateRange == null) return false;

    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1, 1);
    final lastDay = DateTime(now.year, now.month, 0).day;

    return _selectedDateRange!.start.year == lastMonth.year &&
        _selectedDateRange!.start.month == lastMonth.month &&
        _selectedDateRange!.start.day == 1 &&
        _selectedDateRange!.end.year == lastMonth.year &&
        _selectedDateRange!.end.month == lastMonth.month &&
        _selectedDateRange!.end.day == lastDay;
  }

  bool _isThisYearSelected() {
    if (_selectedDateRange == null) return false;

    final now = DateTime.now();
    return _selectedDateRange!.start.year == now.year &&
        _selectedDateRange!.start.month == 1 &&
        _selectedDateRange!.start.day == 1 &&
        _selectedDateRange!.end.year == now.year &&
        _selectedDateRange!.end.month == 12 &&
        _selectedDateRange!.end.day == 31;
  }

  bool _isLastYearSelected() {
    if (_selectedDateRange == null) return false;

    final now = DateTime.now();
    final lastYear = now.year - 1;

    return _selectedDateRange!.start.year == lastYear &&
        _selectedDateRange!.start.month == 1 &&
        _selectedDateRange!.start.day == 1 &&
        _selectedDateRange!.end.year == lastYear &&
        _selectedDateRange!.end.month == 12 &&
        _selectedDateRange!.end.day == 31;
  }
}
