import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/models/currency_model.dart';

/// A data item for the chart legend
class LegendItem {
  final String label;
  final Color color;

  const LegendItem({
    required this.label,
    required this.color,
  });
}

/// A class to store information about a touched spot on the chart
class TouchedSpot {
  final int datasetIndex;
  final int spotIndex;
  final FlSpot spot;

  TouchedSpot({
    required this.datasetIndex,
    required this.spotIndex,
    required this.spot,
  });
}

/// A highly customizable trend chart component with a modern dark theme design,
/// supporting multiple datasets, interactive tooltips, and beautiful styling.
class AdvancedTrendChart extends StatefulWidget {
  /// Primary dataset to display (shown as a filled gradient line)
  final List<FlSpot> primaryData;

  /// Optional secondary dataset (shown as a solid line)
  final List<FlSpot>? secondaryData;

  /// Optional tertiary dataset (shown as a dotted line)
  final List<FlSpot>? tertiaryData;

  /// The currency model for formatting values
  final Currency currency;

  /// Optional title to display above the chart
  final String? title;

  /// Optional subtitle to display above the chart
  final String? subtitle;

  /// Height of the chart
  final double height;

  /// Custom interval for horizontal grid lines
  final double? horizontalInterval;

  /// Custom interval for vertical grid lines
  final double? verticalInterval;

  /// Custom labels for x-axis (if provided, should match length of data points)
  final List<String>? xLabels;

  /// Formatter for primary data tooltips
  final String Function(double x, double y)? primaryTooltipFormatter;

  /// Formatter for secondary data tooltips
  final String Function(double x, double y)? secondaryTooltipFormatter;

  /// Formatter for tertiary data tooltips
  final String Function(double x, double y)? tertiaryTooltipFormatter;

  /// Legend items to display below the chart
  final List<LegendItem>? legendItems;

  /// Use dark theme for the chart
  final bool useDarkTheme;

  const AdvancedTrendChart({
    super.key,
    required this.primaryData,
    this.secondaryData,
    this.tertiaryData,
    required this.currency,
    this.title,
    this.subtitle,
    this.height = 300,
    this.horizontalInterval,
    this.verticalInterval,
    this.xLabels,
    this.primaryTooltipFormatter,
    this.secondaryTooltipFormatter,
    this.tertiaryTooltipFormatter,
    this.legendItems,
    this.useDarkTheme = false,
  });

  @override
  State<AdvancedTrendChart> createState() => _AdvancedTrendChartState();
}

class _AdvancedTrendChartState extends State<AdvancedTrendChart>
    with SingleTickerProviderStateMixin {
  late double _minX;
  late double _maxX;
  late double _minY;
  late double _maxY;
  late bool _hasData;
  late AnimationController _animationController;
  late Animation<double> _animation;
  final List<TouchedSpot> _touchedSpots = [];

  // Gradient colors for primary, secondary, and tertiary datasets
  static const List<List<Color>> _gradientColors = [
    // Primary dataset - Cyan to blue
    [Color(0xFF00E5FF), Color(0xFF2979FF)],
    // Secondary dataset - Green to teal
    [Color(0xFF00E676), Color(0xFF00BFA5)],
    // Tertiary dataset - Purple to pink
    [Color(0xFFD500F9), Color(0xFFFF1744)],
  ];

  @override
  void initState() {
    super.initState();
    _calculateDataBoundaries();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AdvancedTrendChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.primaryData != widget.primaryData ||
        oldWidget.secondaryData != widget.secondaryData ||
        oldWidget.tertiaryData != widget.tertiaryData) {
      _calculateDataBoundaries();
      _animationController.reset();
      _animationController.forward();
    }
  }

  void _calculateDataBoundaries() {
    _hasData = widget.primaryData.isNotEmpty;
    if (!_hasData) return;

    // Initialize min/max with first point of primary data
    if (widget.primaryData.isEmpty) {
      _minX = 0;
      _maxX = 0;
      _minY = 0;
      _maxY = 0;
      return;
    }

    _minX = widget.primaryData.first.x;
    _maxX = widget.primaryData.first.x;
    _minY = widget.primaryData.first.y;
    _maxY = widget.primaryData.first.y;

    // Update from primary data
    for (final spot in widget.primaryData) {
      _minX = _minX < spot.x ? _minX : spot.x;
      _maxX = _maxX > spot.x ? _maxX : spot.x;
      _minY = _minY < spot.y ? _minY : spot.y;
      _maxY = _maxY > spot.y ? _maxY : spot.y;
    }

    // Update from secondary data if it exists
    if (widget.secondaryData != null) {
      for (final spot in widget.secondaryData!) {
        _minX = _minX < spot.x ? _minX : spot.x;
        _maxX = _maxX > spot.x ? _maxX : spot.x;
        _minY = _minY < spot.y ? _minY : spot.y;
        _maxY = _maxY > spot.y ? _maxY : spot.y;
      }
    }

    // Update from tertiary data if it exists
    if (widget.tertiaryData != null) {
      for (final spot in widget.tertiaryData!) {
        _minX = _minX < spot.x ? _minX : spot.x;
        _maxX = _maxX > spot.x ? _maxX : spot.x;
        _minY = _minY < spot.y ? _minY : spot.y;
        _maxY = _maxY > spot.y ? _maxY : spot.y;
      }
    }

    // Add some padding to max Y for better visuals
    _maxY = _maxY + (_maxY - _minY) * 0.1;

    // Ensure minY starts at 0 or lower to include the origin
    _minY = _minY < 0 ? _minY : 0;
  }

  Widget _buildEmptyState(ThemeData theme) {
    return SizedBox(
      height: widget.height,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 48.r,
              color: widget.useDarkTheme
                  ? Colors.white.withValues(alpha: 0.5)
                  : theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            SizedBox(height: 16.h),
            Text(
              'No data available',
              style: TextStyle(
                color: widget.useDarkTheme
                    ? Colors.white.withValues(alpha: 0.7)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomTitle(double value, TitleMeta meta, ThemeData theme) {
    Widget text;
    final int index = value.toInt();
    final titleColor = widget.useDarkTheme ? Colors.white70 : Colors.grey[700];

    String title = 'N/A';

    // Try to get custom label if available
    if (widget.xLabels != null &&
        index >= 0 &&
        index < widget.xLabels!.length) {
      title = widget.xLabels![index];
    } else {
      // Fallback: use index
      title = index.toString();
    }

    text = Text(
      title,
      style: TextStyle(
        color: titleColor,
        fontWeight: FontWeight.bold,
        fontSize: 11.sp,
      ),
      textAlign: TextAlign.center,
    );

    return SideTitleWidget(
      meta: meta,
      child: text,
    );
  }

  Widget _buildLeftTitle(double value, TitleMeta meta, ThemeData theme) {
    if (value == meta.max || value == meta.min) {
      return const SizedBox.shrink();
    }

    final titleColor = widget.useDarkTheme ? Colors.white70 : Colors.grey[700];

    final formatter = NumberFormat.compact();
    return SideTitleWidget(
      meta: meta,
      child: Text(
        formatter.format(value),
        style: TextStyle(
          color: titleColor,
          fontWeight: FontWeight.bold,
          fontSize: 11.sp,
        ),
      ),
    );
  }

  Widget _buildLegendItem(LegendItem item, ThemeData theme) {
    final textColor =
        widget.useDarkTheme ? Colors.white : theme.colorScheme.onSurface;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12.w,
          height: 12.h,
          decoration: BoxDecoration(
            color: item.color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 4.w),
        Text(
          item.label,
          style: TextStyle(
            color: textColor,
            fontSize: 12.sp,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!_hasData) {
      return _buildEmptyState(theme);
    }

    final backgroundColor =
        widget.useDarkTheme ? const Color(0xFF2C2C43) : theme.cardColor;

    final titleColor =
        widget.useDarkTheme ? Colors.white : theme.colorScheme.onSurface;

    final subtitleColor = widget.useDarkTheme
        ? Colors.white70
        : theme.colorScheme.onSurface.withValues(alpha: 0.7);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.subtitle != null) ...[
              Text(
                widget.subtitle!,
                style: TextStyle(
                  color: subtitleColor,
                  fontSize: 12.sp,
                ),
              ),
              SizedBox(height: 4.h),
            ],
            if (widget.title != null) ...[
              Text(
                widget.title!,
                style: TextStyle(
                  color: titleColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18.sp,
                ),
              ),
              SizedBox(height: 24.h),
            ],
            SizedBox(
              height: widget.height,
              child: Padding(
                padding: EdgeInsets.only(right: 16.w, bottom: 8.h),
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return LineChart(
                      _createChartData(theme),
                    );
                  },
                ),
              ),
            ),
            if (widget.legendItems != null &&
                widget.legendItems!.isNotEmpty) ...[
              SizedBox(height: 16.h),
              Wrap(
                spacing: 16.w,
                runSpacing: 8.h,
                children: widget.legendItems!
                    .map((item) => _buildLegendItem(item, theme))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  LineChartData _createChartData(ThemeData theme) {
    final formatter = NumberFormat.currency(
      symbol: widget.currency.symbol,
      decimalDigits: 0,
    );

    return LineChartData(
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          // tooltipBgColor:
          //   widget.useDarkTheme ? const Color(0xFF1A1A30) : Colors.white,
          tooltipBorderRadius: BorderRadius.circular(8.r),
          tooltipPadding: EdgeInsets.symmetric(
            horizontal: 12.w,
            vertical: 8.h,
          ),
          tooltipMargin: 8,
          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            return touchedBarSpots.map((barSpot) {
              final datasetIndex = barSpot.barIndex;
              final x = barSpot.x;
              final y = barSpot.y;

              String tooltipText;
              Color color;

              // Use appropriate formatter based on dataset index
              if (datasetIndex == 0) {
                tooltipText = widget.primaryTooltipFormatter != null
                    ? widget.primaryTooltipFormatter!(x, y)
                    : formatter.format(y);
                color = _gradientColors[0][0];
              } else if (datasetIndex == 1) {
                tooltipText = widget.secondaryTooltipFormatter != null
                    ? widget.secondaryTooltipFormatter!(x, y)
                    : formatter.format(y);
                color = _gradientColors[1][0];
              } else {
                tooltipText = widget.tertiaryTooltipFormatter != null
                    ? widget.tertiaryTooltipFormatter!(x, y)
                    : formatter.format(y);
                color = _gradientColors[2][0];
              }

              return LineTooltipItem(
                tooltipText,
                TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.sp,
                ),
              );
            }).toList();
          },
          fitInsideHorizontally: true,
          fitInsideVertically: true,
        ),
        touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
          if (event is FlTapUpEvent || event is FlPanEndEvent) {
            setState(() {
              _touchedSpots.clear();
            });
            return;
          }

          if (response == null || response.lineBarSpots == null) {
            setState(() {
              _touchedSpots.clear();
            });
            return;
          }

          setState(() {
            _touchedSpots.clear();
            _touchedSpots.addAll(
              response.lineBarSpots!.map((spot) => TouchedSpot(
                    datasetIndex: spot.barIndex,
                    spotIndex: spot.spotIndex,
                    spot: spot,
                  )),
            );
          });
        },
        handleBuiltInTouches: true,
      ),
      gridData: FlGridData(
        show: true,
        horizontalInterval: widget.horizontalInterval,
        verticalInterval: widget.verticalInterval,
        getDrawingHorizontalLine: (value) => FlLine(
          color: widget.useDarkTheme
              ? Colors.white.withValues(alpha: 0.1)
              : theme.dividerColor.withValues(alpha: 0.2),
          strokeWidth: 1,
          dashArray: [5, 5],
        ),
        getDrawingVerticalLine: (value) => FlLine(
          color: widget.useDarkTheme
              ? Colors.white.withValues(alpha: 0.1)
              : theme.dividerColor.withValues(alpha: 0.2),
          strokeWidth: 1,
          dashArray: [5, 5],
        ),
        drawVerticalLine: true,
        drawHorizontalLine: true,
      ),
      titlesData: FlTitlesData(
        show: true,
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) =>
                _buildBottomTitle(value, meta, theme),
            reservedSize: 24.h,
            interval: 1,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) =>
                _buildLeftTitle(value, meta, theme),
            reservedSize: 40.w,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: widget.useDarkTheme ? false : true,
        border: Border(
          bottom: BorderSide(
            color: widget.useDarkTheme
                ? Colors.white.withValues(alpha: 0.2)
                : theme.dividerColor.withValues(alpha: 0.2),
            width: 1,
          ),
          left: BorderSide(
            color: widget.useDarkTheme
                ? Colors.white.withValues(alpha: 0.2)
                : theme.dividerColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      minX: _minX,
      maxX: _maxX,
      minY: _minY,
      maxY: _maxY,
      lineBarsData: _getLineBarsData(),
      backgroundColor: Colors.transparent,
    );
  }

  List<LineChartBarData> _getLineBarsData() {
    final List<LineChartBarData> lineBarsData = [];

    // Calculate animation progress for spots
    final animValue = _animation.value;

    // Primary data (with gradient fill)
    if (widget.primaryData.isNotEmpty) {
      final spots = widget.primaryData.map((spot) {
        return FlSpot(
          spot.x,
          spot.y * animValue,
        );
      }).toList();

      lineBarsData.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.3,
          gradient: LinearGradient(
            colors: _gradientColors[0],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          barWidth: 3.5,
          isStrokeCapRound: true,
          dotData: _getDotData(0),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                _gradientColors[0][0].withValues(alpha: 0.5),
                _gradientColors[0][1].withValues(alpha: 0.05),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      );
    }

    // Secondary data (solid line)
    if (widget.secondaryData != null && widget.secondaryData!.isNotEmpty) {
      final spots = widget.secondaryData!.map((spot) {
        return FlSpot(
          spot.x,
          spot.y * animValue,
        );
      }).toList();

      lineBarsData.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.3,
          gradient: LinearGradient(
            colors: _gradientColors[1],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: _getDotData(1),
          belowBarData: BarAreaData(show: false),
        ),
      );
    }

    // Tertiary data (dotted line)
    if (widget.tertiaryData != null && widget.tertiaryData!.isNotEmpty) {
      final spots = widget.tertiaryData!.map((spot) {
        return FlSpot(
          spot.x,
          spot.y * animValue,
        );
      }).toList();

      lineBarsData.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.25,
          gradient: LinearGradient(
            colors: _gradientColors[2],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: _getDotData(2),
          dashArray: widget.useDarkTheme ? null : [4, 4],
          belowBarData: BarAreaData(show: false),
        ),
      );
    }

    return lineBarsData;
  }

  FlDotData _getDotData(int datasetIndex) {
    return FlDotData(
      show: true,
      getDotPainter: (spot, percent, barData, index) {
        final isTouched = _touchedSpots.any(
          (touchedSpot) =>
              touchedSpot.datasetIndex == datasetIndex &&
              touchedSpot.spotIndex == index,
        );

        final color = datasetIndex == 0
            ? _gradientColors[0][0]
            : datasetIndex == 1
                ? _gradientColors[1][0]
                : _gradientColors[2][0];

        return FlDotCirclePainter(
          radius: isTouched
              ? 6
              : datasetIndex == 0
                  ? 3.5
                  : 3,
          color: color,
          strokeWidth: isTouched ? 2 : 0,
          strokeColor: Colors.white,
        );
      },
      checkToShowDot: (spot, barData) {
        // Only show dots when touched or for specific data points
        return _touchedSpots.any((touchedSpot) =>
                touchedSpot.datasetIndex == barData.spots.indexOf(spot) &&
                touchedSpot.spotIndex == barData.spots.indexOf(spot)) ||
            spot.x % 2 == 0; // Show dot for every other point
      },
    );
  }
}
