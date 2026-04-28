import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../cubit/export_data_cubit.dart';
import 'package:finance_track/core/localization/localization.dart';

class ExportDataScreen extends StatelessWidget {
  const ExportDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ExportDataCubit()..setPeriod(ExportPeriod.thisMonth),
      child: const _ExportDataView(),
    );
  }
}

class _ExportDataView extends StatelessWidget {
  const _ExportDataView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const LocalizedText('Export Data'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const LocalizedText('Export Information'),
                  content: const LocalizedText('You can export your transactions to a CSV file. The file will include all transaction details including date, amount, category, and description.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const LocalizedText('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<ExportDataCubit, ExportDataState>(
        builder: (context, state) {
          return Column(
            children: [
              _buildDateRangeSelector(context, state),
              Expanded(
                child: _buildTransactionList(context, state),
              ),
              _buildBottomBar(context, state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDateRangeSelector(BuildContext context, ExportDataState state) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LocalizedText('Select Date Range',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ExportPeriod.values.map((period) {
                final isSelected = state.selectedPeriod == period;
                return Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: ChoiceChip(
                    label: LocalizedText(
                      _getPeriodLabel(period),
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        if (period == ExportPeriod.custom) {
                          // When selecting Custom, initialize with current date range or today
                          final now = DateTime.now();
                          final startDate = state.startDate ??
                              DateTime(now.year, now.month, now.day);
                          final endDate = state.endDate ?? now;
                          context
                              .read<ExportDataCubit>()
                              .setCustomDateRange(startDate, endDate);
                        } else {
                          context.read<ExportDataCubit>().setPeriod(period);
                        }
                      }
                    },
                    backgroundColor: Colors.white,
                    selectedColor: const Color(0xFF6C63FF),
                    checkmarkColor: Colors.white,
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF6C63FF)
                          : Colors.grey[300]!,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          if (state.selectedPeriod == ExportPeriod.custom) ...[
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: _buildDateField(
                    context,
                    'Start Date',
                    state.startDate,
                    (date) =>
                        context.read<ExportDataCubit>().setCustomDateRange(
                              date,
                              state.endDate ?? DateTime.now(),
                            ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildDateField(
                    context,
                    'End Date',
                    state.endDate,
                    (date) =>
                        context.read<ExportDataCubit>().setCustomDateRange(
                              state.startDate ?? DateTime.now(),
                              date,
                            ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateField(
    BuildContext context,
    String label,
    DateTime? date,
    ValueChanged<DateTime> onDateSelected,
  ) {
    return InkWell(
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF6C63FF),
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Colors.black,
                ),
              ),
              child: child!,
            );
          },
        );
        if (selectedDate != null) {
          onDateSelected(selectedDate);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 18.r,
              color: Colors.grey[600],
            ),
            SizedBox(width: 8.w),
            LocalizedText(
              date != null
                  ? DateFormat('MMM dd, yyyy').format(date)
                  : 'Select $label',
              style: TextStyle(
                fontSize: 14.sp,
                color: date != null ? Colors.black87 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList(BuildContext context, ExportDataState state) {
    if (state.transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64.r,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16.h),
            LocalizedText('No transactions found',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8.h),
            LocalizedText('Try selecting a different date range',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              LocalizedText('${state.transactions.length} Transactions',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              LocalizedText('Total: ${formatter.format(state.transactions.fold<double>(0, (sum, t) => sum + (t['amount'] as double)))}',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: state.transactions.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: Colors.grey[200],
            ),
            itemBuilder: (context, index) {
              final transaction = state.transactions[index];
              return ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 8.h,
                ),
                leading: Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    transaction['type'] == 'income'
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    color: const Color(0xFF6C63FF),
                    size: 20.r,
                  ),
                ),
                title: LocalizedText(
                  transaction['description'] ?? 'No description',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocalizedText(
                      DateFormat('MMM dd, yyyy').format(
                        transaction['date'] as DateTime,
                      ),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (transaction['category'] != null)
                      LocalizedText(
                        transaction['category'] as String,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
                trailing: LocalizedText(
                  formatter.format(transaction['amount']),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: transaction['type'] == 'income'
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, ExportDataState state) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state.error != null) ...[
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red.shade700,
                    size: 20.r,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: LocalizedText(
                      state.error!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: state.isLoading || state.transactions.isEmpty
                  ? null
                  : () => context.read<ExportDataCubit>().exportTransactions(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 0,
              ),
              child: state.isLoading
                  ? SizedBox(
                      height: 20.h,
                      width: 20.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.file_download_outlined,
                          size: 20.r,
                        ),
                        SizedBox(width: 8.w),
                        LocalizedText('Export ${state.transactions.length} Transactions',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
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

  String _getPeriodLabel(ExportPeriod period) {
    switch (period) {
      case ExportPeriod.today:
        return 'Today';
      case ExportPeriod.thisWeek:
        return 'This Week';
      case ExportPeriod.thisMonth:
        return 'This Month';
      case ExportPeriod.last30Days:
        return 'Last 30 Days';
      case ExportPeriod.last3Months:
        return 'Last 3 Months';
      case ExportPeriod.last6Months:
        return 'Last 6 Months';
      case ExportPeriod.last12Months:
        return 'Last 12 Months';
      case ExportPeriod.allTime:
        return 'All Time';
      case ExportPeriod.custom:
        return 'Custom Range';
    }
  }
}
