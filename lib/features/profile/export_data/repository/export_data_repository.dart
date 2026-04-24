import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import '../../../../data/objectbox.dart';
import '../../../../data/models/expense_model.dart';
import '../../../../data/models/income_model.dart';
import '../../../../objectbox.g.dart';

class ExportDataRepository {
  // Get ObjectBox instance
  final ObjectBox _objectBox = ObjectBox.instance;

  Future<List<Map<String, dynamic>>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Get all expenses from ObjectBox
      List<Expense> expenses = [];
      List<Income> incomes = [];

      // For expenses
      if (startDate != null && endDate != null) {
        // Both dates provided
        final expenseQueryBuilder = _objectBox.expenseBox.query(Expense_.date
            .between(startDate.millisecondsSinceEpoch,
                endDate.add(const Duration(days: 1)).millisecondsSinceEpoch))
          ..order(Expense_.date, flags: Order.descending);

        final expenseQuery = expenseQueryBuilder.build();
        expenses = expenseQuery.find();
        expenseQuery.close();
      } else if (startDate != null) {
        // Only start date provided
        final expenseQueryBuilder = _objectBox.expenseBox
            .query(Expense_.date.greaterThan(startDate.millisecondsSinceEpoch))
          ..order(Expense_.date, flags: Order.descending);

        final expenseQuery = expenseQueryBuilder.build();
        expenses = expenseQuery.find();
        expenseQuery.close();
      } else if (endDate != null) {
        // Only end date provided
        final expenseQueryBuilder = _objectBox.expenseBox.query(Expense_.date
            .lessThan(
                endDate.add(const Duration(days: 1)).millisecondsSinceEpoch))
          ..order(Expense_.date, flags: Order.descending);

        final expenseQuery = expenseQueryBuilder.build();
        expenses = expenseQuery.find();
        expenseQuery.close();
      } else {
        // No date filtering
        final expenseQueryBuilder = _objectBox.expenseBox.query()
          ..order(Expense_.date, flags: Order.descending);

        final expenseQuery = expenseQueryBuilder.build();
        expenses = expenseQuery.find();
        expenseQuery.close();
      }

      // For incomes
      if (startDate != null && endDate != null) {
        // Both dates provided
        final incomeQueryBuilder = _objectBox.incomeBox.query(Income_.date
            .between(startDate.millisecondsSinceEpoch,
                endDate.add(const Duration(days: 1)).millisecondsSinceEpoch))
          ..order(Income_.date, flags: Order.descending);

        final incomeQuery = incomeQueryBuilder.build();
        incomes = incomeQuery.find();
        incomeQuery.close();
      } else if (startDate != null) {
        // Only start date provided
        final incomeQueryBuilder = _objectBox.incomeBox
            .query(Income_.date.greaterThan(startDate.millisecondsSinceEpoch))
          ..order(Income_.date, flags: Order.descending);

        final incomeQuery = incomeQueryBuilder.build();
        incomes = incomeQuery.find();
        incomeQuery.close();
      } else if (endDate != null) {
        // Only end date provided
        final incomeQueryBuilder = _objectBox.incomeBox.query(Income_.date
            .lessThan(
                endDate.add(const Duration(days: 1)).millisecondsSinceEpoch))
          ..order(Income_.date, flags: Order.descending);

        final incomeQuery = incomeQueryBuilder.build();
        incomes = incomeQuery.find();
        incomeQuery.close();
      } else {
        // No date filtering
        final incomeQueryBuilder = _objectBox.incomeBox.query()
          ..order(Income_.date, flags: Order.descending);

        final incomeQuery = incomeQueryBuilder.build();
        incomes = incomeQuery.find();
        incomeQuery.close();
      }

      // Convert expenses to transaction items
      final expenseItems = expenses.map((expense) {
        final category = ExpenseCategory.values[expense.categoryIndex];
        return {
          'id': expense.uuid,
          'date': expense.date,
          'type': 'expense',
          'amount': expense.amount,
          'category': category.displayName,
          'description': expense.title,
          'notes': expense.notes,
          'payment_method': expense.paymentMethod,
        };
      }).toList();

      // Convert incomes to transaction items
      final incomeItems = incomes.map((income) {
        final category = IncomeCategory.values[income.categoryIndex];
        return {
          'id': income.uuid,
          'date': income.date,
          'type': 'income',
          'amount': income.amount,
          'category': category.displayName,
          'description': income.title,
          'notes': income.notes,
          'source': income.source,
        };
      }).toList();

      // Combine and sort by date
      final allTransactions = [...expenseItems, ...incomeItems]..sort(
          (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

      return allTransactions;
    } catch (e) {
      throw Exception('Failed to fetch transactions: $e');
    }
  }

  Future<void> exportTransactions({
    required List<Map<String, dynamic>> transactions,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Convert transactions to CSV format with minimal, essential columns
      final List<List<dynamic>> csvData = [
        [
          'Date',
          'Type',
          'Category',
          'Description',
          'Amount',
        ],
        ...transactions.map((transaction) => [
              DateFormat('yyyy-MM-dd').format(transaction['date'] as DateTime),
              transaction['type'] == 'expense' ? 'Expense' : 'Income',
              transaction['category'] as String? ?? '',
              transaction['description'] as String? ?? '',
              transaction['amount']?.toString() ?? '0',
            ]),
      ];

      final csvString = const ListToCsvConverter().convert(csvData);

      // Generate filename with date range
      final filename =
          'transactions_${_getDateRangeString(startDate, endDate)}.csv';

      // Share the CSV file
      await Share.shareXFiles(
        [
          XFile.fromData(
            utf8.encode(csvString),
            name: filename,
            mimeType: 'text/csv',
          ),
        ],
        text: 'Transaction Export',
      );
    } catch (e) {
      throw Exception('Failed to export transactions: $e');
    }
  }

  String _getDateRangeString(DateTime? startDate, DateTime? endDate) {
    if (startDate == null && endDate == null) {
      return 'all_time';
    }

    final start = startDate != null
        ? DateFormat('yyyyMMdd').format(startDate)
        : 'beginning';
    final end =
        endDate != null ? DateFormat('yyyyMMdd').format(endDate) : 'today';

    return '${start}_to_$end';
  }
}
