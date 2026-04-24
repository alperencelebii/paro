import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../profile/currency/bloc/currency/currency_bloc.dart';
import '../../profile/currency/bloc/currency/currency_state.dart';
import '../../../core/models/currency_model.dart';
import 'package:intl/intl.dart';

class DailySpendingCard extends StatefulWidget {
  final Map<DateTime, double> dailySpending;
  final Map<DateTime, double> dailyIncome;

  const DailySpendingCard({
    super.key,
    required this.dailySpending,
    this.dailyIncome = const {},
  });

  @override
  State<DailySpendingCard> createState() => _DailySpendingCardState();
}

class _DailySpendingCardState extends State<DailySpendingCard> {
  int? touchedIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.dailySpending.isEmpty && widget.dailyIncome.isEmpty) {
      return _buildEmptyState(context);
    }

    // Combine both maps to get all unique dates
    final allDates = <DateTime>{};
    allDates.addAll(widget.dailySpending.keys);
    allDates.addAll(widget.dailyIncome.keys);

    // Sort the dates
    final sortedDates = allDates.toList()..sort((a, b) => a.compareTo(b));

    // Find max amount for Y-axis scaling
    final maxExpense = widget.dailySpending.isEmpty
        ? 0.0
        : widget.dailySpending.values
            .reduce((max, value) => value > max ? value : max);
    final maxIncome = widget.dailyIncome.isEmpty
        ? 0.0
        : widget.dailyIncome.values
            .reduce((max, value) => value > max ? value : max);
    final maxAmount = [maxExpense, maxIncome]
        .reduce((max, value) => value > max ? value : max);

    // Calculate Y-axis intervals
    final yInterval = _calculateYAxisInterval(maxAmount);
    final maxY = ((maxAmount ~/ yInterval) + 1) * yInterval.toDouble();

    // Map dates to sequential indices for x-axis
    final datesIndices = <DateTime, int>{};
    for (int i = 0; i < sortedDates.length; i++) {
      datesIndices[sortedDates[i]] = i;
    }

    // Create spots for spending and income line charts
    final spendingSpots = <FlSpot>[];
    final incomeSpots = <FlSpot>[];

    for (final date in sortedDates) {
      final index = datesIndices[date]!.toDouble();

      // Add spending spot if exists for this date
      if (widget.dailySpending.containsKey(date)) {
        spendingSpots.add(FlSpot(index, widget.dailySpending[date]!));
      }

      // Add income spot if exists for this date
      if (widget.dailyIncome.containsKey(date)) {
        incomeSpots.add(FlSpot(index, widget.dailyIncome[date]!));
      }
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, 4),
            blurRadius: 20,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.show_chart_rounded,
                        color: theme.colorScheme.primary,
                        size: 20.r,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'Daily Transactions',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Legend
            Padding(
              padding: EdgeInsets.symmetric(vertical: 4.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(context, Colors.green.shade600, 'Income'),
                  SizedBox(width: 24.w),
                  _buildLegendItem(
                      context, Colors.redAccent.shade700, 'Expense'),
                ],
              ),
            ),

            SizedBox(height: 12.h),

            // Chart Section
            SizedBox(
              height: 240.h,
              child: Stack(
                children: [
                  LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: yInterval,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: theme.dividerColor.withValues(alpha: 0.2),
                            strokeWidth: 1,
                            dashArray: [5, 5],
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: yInterval,
                            reservedSize: 45,
                            getTitlesWidget: (value, meta) {
                              return BlocBuilder<CurrencyBloc, CurrencyState>(
                                builder: (context, state) {
                                  final currency = state is CurrencyLoaded
                                      ? state.selectedCurrency
                                      : Currencies.inr;
                                  return Text(
                                    value >= 1000
                                        ? '${currency.symbol}${(value / 1000).toStringAsFixed(0)}K'
                                        : '${currency.symbol}${value.toStringAsFixed(0)}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.textTheme.bodySmall?.color
                                          ?.withValues(alpha: 0.7),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: sortedDates.length > 10 ? 2 : 1,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= sortedDates.length) {
                                return const SizedBox.shrink();
                              }
                              final date = sortedDates[value.toInt()];
                              return Padding(
                                padding: EdgeInsets.only(top: 8.h),
                                child: Text(
                                  date.day.toString(),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.textTheme.bodySmall?.color
                                        ?.withValues(alpha: 0.7),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: sortedDates.length.toDouble() - 1,
                      minY: 0,
                      maxY: maxY,
                      lineBarsData: [
                        // Income Line
                        if (incomeSpots.isNotEmpty)
                          LineChartBarData(
                            spots: incomeSpots,
                            isCurved: true,
                            color: Colors.green.shade600,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(
                                  radius: 4,
                                  color: Colors.green.shade600,
                                  strokeWidth: 2,
                                  strokeColor: Colors.white,
                                );
                              },
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.green.withValues(alpha: 0.1),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.green.shade300.withValues(alpha: 0.2),
                                  Colors.green.shade50.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),

                        // Expense Line
                        if (spendingSpots.isNotEmpty)
                          LineChartBarData(
                            spots: spendingSpots,
                            isCurved: true,
                            color: Colors.redAccent.shade700,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(
                                  radius: 4,
                                  color: Colors.redAccent.shade700,
                                  strokeWidth: 2,
                                  strokeColor: Colors.white,
                                );
                              },
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.redAccent.withValues(alpha: 0.1),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.redAccent.shade100
                                      .withValues(alpha: 0.2),
                                  Colors.redAccent.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                      ],
                      lineTouchData: LineTouchData(
                        enabled: true,
                        touchSpotThreshold: 10,
                        handleBuiltInTouches: true,
                        touchTooltipData: LineTouchTooltipData(
                          // tooltipBgColor: Colors.white,
                          tooltipBorderRadius: BorderRadius.circular(8.r),
                          tooltipMargin: 8,
                          tooltipPadding: EdgeInsets.all(12.r),
                          tooltipBorder:
                              BorderSide(color: Colors.grey.shade200),
                          fitInsideHorizontally: true,
                          fitInsideVertically: true,
                          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                            // Group spots by date
                            final Map<DateTime, List<LineBarSpot>> spotsByDate =
                                {};

                            for (var barSpot in touchedBarSpots) {
                              final date = sortedDates[barSpot.x.toInt()];
                              if (!spotsByDate.containsKey(date)) {
                                spotsByDate[date] = [];
                              }
                              spotsByDate[date]!.add(barSpot);
                            }

                            return touchedBarSpots.map((barSpot) {
                              final date = sortedDates[barSpot.x.toInt()];
                              final spots = spotsByDate[date]!;

                              // If this isn't the first spot for this date, don't show tooltip
                              if (spots.indexOf(barSpot) > 0) {
                                return null;
                              }

                              final currency =
                                  BlocProvider.of<CurrencyBloc>(context).state
                                          is CurrencyLoaded
                                      ? (BlocProvider.of<CurrencyBloc>(context)
                                              .state as CurrencyLoaded)
                                          .selectedCurrency
                                      : Currencies.inr;

                              // Build all content for this date
                              final List<TextSpan> tooltipSpans = [];

                              for (var spot in spots) {
                                final isIncome = spot.barIndex == 0;
                                final value = spot.y;

                                tooltipSpans.add(
                                  TextSpan(
                                    text:
                                        '${isIncome ? 'Income' : 'Expense'}: ${currency.symbol}${value.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      color: isIncome
                                          ? Colors.green.shade600
                                          : Colors.redAccent.shade700,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                );

                                // Add newline if not the last item
                                if (spot != spots.last) {
                                  tooltipSpans.add(const TextSpan(text: '\n'));
                                }
                              }

                              return LineTooltipItem(
                                '${DateFormat('MMM d').format(date)}\n',
                                TextStyle(
                                  color: theme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.sp,
                                ),
                                children: tooltipSpans,
                              );
                            }).toList();
                          },
                        ),
                        getTouchedSpotIndicator:
                            (LineChartBarData barData, List<int> spotIndexes) {
                          return spotIndexes.map((spotIndex) {
                            return TouchedSpotIndicatorData(
                              FlLine(
                                color: barData.color ?? Colors.blue,
                                strokeWidth: 2,
                                dashArray: [3, 3],
                              ),
                              FlDotData(
                                getDotPainter: (spot, percent, barData, index) {
                                  return FlDotCirclePainter(
                                    radius: 6,
                                    color: barData.color ?? Colors.blue,
                                    strokeWidth: 2,
                                    strokeColor: Colors.white,
                                  );
                                },
                              ),
                            );
                          }).toList();
                        },
                        touchCallback: (FlTouchEvent event,
                            LineTouchResponse? touchResponse) {
                          if (event is FlPanEndEvent ||
                              event is FlLongPressEnd ||
                              event is FlTapUpEvent ||
                              event is FlPointerExitEvent) {
                            Future.delayed(const Duration(milliseconds: 300),
                                () {
                              if (mounted) {
                                setState(() {
                                  touchedIndex = null;
                                });
                              }
                            });
                          } else if (touchResponse?.lineBarSpots != null &&
                              touchResponse!.lineBarSpots!.isNotEmpty) {
                            setState(() {
                              touchedIndex =
                                  touchResponse.lineBarSpots![0].x.toInt();
                            });
                          }
                        },
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

  Widget _buildLegendItem(BuildContext context, Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12.r,
          height: 12.r,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, 4),
            blurRadius: 20,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart_rounded,
              size: 48.r,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            SizedBox(height: 16.h),
            Text(
              'No daily transaction data',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Add transactions to see daily spending and income trends',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateYAxisInterval(double maxValue) {
    if (maxValue <= 0) return 100;
    if (maxValue <= 100) return 20;
    if (maxValue <= 500) return 100;
    if (maxValue <= 1000) return 200;
    if (maxValue <= 5000) return 1000;
    if (maxValue <= 10000) return 2000;
    if (maxValue <= 50000) return 10000;
    if (maxValue <= 100000) return 20000;
    return 50000;
  }
}
