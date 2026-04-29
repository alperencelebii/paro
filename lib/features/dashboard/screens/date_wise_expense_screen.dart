import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:finance_track/core/localization/localization.dart';

import '../../../core/extensions/currency_context_extension.dart';
import '../../../data/repositories/expense_repository.dart';
import '../../../data/repositories/income_repository.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/models/income_model.dart';
import '../../expense_list/screens/expense_list_screen.dart';
import '../../income_list/screens/income_list_screen.dart';
import '../cubit/date_wise_expense_cubit.dart';

/// Screen showing date-wise expenses with scrollable date selector
class DateWiseExpenseScreen extends StatefulWidget {
  const DateWiseExpenseScreen({super.key});

  @override
  State<DateWiseExpenseScreen> createState() => _DateWiseExpenseScreenState();
}

class _DateWiseExpenseScreenState extends State<DateWiseExpenseScreen> {
  DateTime? _selectedDate;
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _dateItemKeys = {};

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DateWiseExpenseCubit(
        expenseRepository: context.read<ExpenseRepository>(),
        incomeRepository: context.read<IncomeRepository>(),
      )..loadDateWiseData(days: 30),
      child: Scaffold(
        appBar: AppBar(
          title: const LocalizedText('Date-wise Expenses'),
          backgroundColor: const Color(0xFF1D4ED8),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: BlocBuilder<DateWiseExpenseCubit, DateWiseExpenseState>(
          builder: (context, state) {
            if (state is DateWiseExpenseLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is DateWiseExpenseError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64.r, color: Colors.red),
                    SizedBox(height: 16.h),
                    LocalizedText('Error: ${state.message}'),
                  ],
                ),
              );
            }

            if (state is DateWiseExpenseLoaded) {
              if (state.dailyData.isEmpty) {
                return _buildEmptyState(context);
              }

              // Initialize selected date to today if not set
              if (_selectedDate == null) {
                _selectedDate = state.dailyData.last.date;
                // Scroll to selected date after first frame
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToSelectedDate(state);
                });
              }

              final selectedData = state.dailyData.firstWhere(
                (data) => _isSameDay(data.date, _selectedDate!),
                orElse: () => state.dailyData.last,
              );

              final transactions = state.getTransactionsForDate(_selectedDate!);

              return Column(
                children: [
                  // Date selector
                  _buildDateSelector(context, state),
                  // Summary cards
                  _buildSummaryCards(context, selectedData, state),
                  // Transactions list
                  Expanded(
                    child: _buildTransactionsList(context, transactions, state),
                  ),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 64.r, color: Colors.grey),
          SizedBox(height: 16.h),
          LocalizedText('No data available',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8.h),
          LocalizedText('Add expenses and income to see date-wise analysis',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context, DateWiseExpenseLoaded state) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    _dateItemKeys.removeWhere((key, value) => key >= state.dailyData.length);

    return Container(
      height: 130.h,
      padding: EdgeInsets.symmetric(vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: state.dailyData.length,
        itemBuilder: (context, index) {
          final data = state.dailyData[index];
          final isSelected =
              _selectedDate != null && _isSameDay(data.date, _selectedDate!);
          final isToday = _isSameDay(data.date, now);
          final itemKey = _dateItemKeys.putIfAbsent(index, () => GlobalKey());

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = data.date;
              });
              // Scroll to selected date
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToSelectedDate(state);
              });
            },
            child: AnimatedContainer(
              key: itemKey,
              height: 80.h,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: isSelected ? 70.w : 65.w,
              margin: EdgeInsets.only(right: 10.w),
              padding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: isSelected ? 7.h : 5.h,
              ),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF1D4ED8), Color(0xFF1E40AF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: !isSelected
                    ? isToday
                        ? Colors.white
                        : theme.colorScheme.surface
                    : null,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF1D4ED8)
                      : isToday
                          ? const Color(0xFF1D4ED8)
                          : Colors.grey.shade300,
                  width: isSelected
                      ? 2
                      : isToday
                          ? 2
                          : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF1D4ED8).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LocalizedText(
                    DateFormat('EEE').format(data.date),
                    style: TextStyle(
                      fontSize: isSelected ? 10.sp : 10.sp,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.9)
                          : Colors.grey.shade600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  LocalizedText(
                    DateFormat('d').format(data.date),
                    style: TextStyle(
                      fontSize: isSelected ? 24.sp : 20.sp,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  LocalizedText(
                    DateFormat('MMM').format(data.date),
                    style: TextStyle(
                      fontSize: isSelected ? 11.sp : 10.sp,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.8)
                          : Colors.grey.shade600,
                    ),
                  ),
                  if (data.expense > 0 || data.income > 0)
                    Container(
                      margin: EdgeInsets.only(top: 6.h),
                      width: 6.w,
                      height: 6.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            isSelected ? Colors.white : const Color(0xFF1D4ED8),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(
    BuildContext context,
    DailyExpenseData selectedData,
    DateWiseExpenseLoaded state,
  ) {
    final currency = context.selectedCurrency;
    final formatter = NumberFormat.currency(
      symbol: currency.symbol,
      decimalDigits: 2,
    );

    return Container(
      padding: EdgeInsets.all(16.r),
      color: Colors.grey.shade50,
      child: Row(
        children: [
          // Total Expense Card
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.trending_down,
                          color: Colors.red.shade700, size: 20.r),
                      SizedBox(width: 4.w),
                      LocalizedText('Expense',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  LocalizedText(
                    formatter.format(selectedData.expense),
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 12.w),
          // Total Income Card
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.trending_up,
                          color: Colors.green.shade700, size: 20.r),
                      SizedBox(width: 4.w),
                      LocalizedText('Income',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  LocalizedText(
                    formatter.format(selectedData.income),
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900,
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

  Widget _buildTransactionsList(
    BuildContext context,
    List<dynamic> transactions,
    DateWiseExpenseLoaded state,
  ) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64.r,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16.h),
            LocalizedText('No transactions',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 8.h),
            LocalizedText('Add expenses or income for this date',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      itemCount: transactions.length,
      // separatorBuilder: (context, index) => SizedBox(height: 8.h),
      itemBuilder: (context, index) {
        final transaction = transactions[index];

        // Use standard widgets for expenses and income
        if (transaction is Expense) {
          return ExpenseListItemWidget(expense: transaction);
        } else if (transaction is Income) {
          return IncomeListItemWidget(income: transaction);
        }

        return const SizedBox.shrink();
      },
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  void _scrollToSelectedDate(DateWiseExpenseLoaded state) {
    if (_selectedDate == null || !_scrollController.hasClients) return;

    final selectedIndex = state.dailyData.indexWhere(
      (data) => _isSameDay(data.date, _selectedDate!),
    );

    if (selectedIndex != -1) {
      final itemKey = _dateItemKeys[selectedIndex];
      final itemContext = itemKey?.currentContext;
      if (itemContext != null) {
        Scrollable.ensureVisible(
          itemContext,
          alignment: 0.5,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
        );
      } else {
        final itemWidth = 86.w;
        final screenWidth = MediaQuery.of(context).size.width;
        final centerOffset = (screenWidth / 2) - (itemWidth / 2);
        _scrollController.animateTo(
          (selectedIndex * itemWidth) - centerOffset,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
        );
      }
    }
  }
}
