import 'dart:convert';
import 'dart:io';

import 'package:finance_track/data/repositories/objectbox_expense_repository.dart';
import 'package:finance_track/data/repositories/objectbox_income_repository.dart';
import 'package:finance_track/features/monthly_summary/models/transaction_item.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Service for exporting transaction data
class ExportService {
  final ObjectBoxExpenseRepository expenseRepository;
  final ObjectBoxIncomeRepository incomeRepository;

  /// Constructor
  ExportService({
    required this.expenseRepository,
    required this.incomeRepository,
  });

  /// Convert all transactions to a unified format for export
  Future<List<TransactionItem>> _getAllTransactions() async {
    final expenses = await expenseRepository.getAllExpenses();
    final incomes = await incomeRepository.getAllIncomes();

    final transactions = <TransactionItem>[];

    // Add all expenses
    for (final expense in expenses) {
      transactions.add(TransactionItem.fromExpense(expense));
    }

    // Add all incomes
    for (final income in incomes) {
      transactions.add(TransactionItem.fromIncome(income));
    }

    // Sort by date (newest first)
    transactions.sort((a, b) => b.date.compareTo(a.date));

    return transactions;
  }

  /// Export transactions as CSV
  Future<String> exportAsCSV() async {
    final transactions = await _getAllTransactions();
    final dateFormat = DateFormat('yyyy-MM-dd');

    // Create CSV header
    final csvData = StringBuffer(
        'ID,Title,Amount,Date,Category,Type,Payment Method/Source,Notes\n');

    // Add rows for each transaction
    for (final transaction in transactions) {
      final row = [
        transaction.id,
        _escapeCsvField(transaction.title),
        transaction.amount.toStringAsFixed(2),
        dateFormat.format(transaction.date),
        _escapeCsvField(transaction.categoryName),
        transaction.isExpense ? 'Expense' : 'Income',
        _escapeCsvField(transaction.paymentMethodOrSource ?? ''),
        _escapeCsvField(transaction.notes ?? ''),
      ].join(',');

      csvData.writeln(row);
    }

    // Save to file
    final file = await _saveToFile(csvData.toString(), 'transactions.csv');
    return file.path;
  }

  /// Export transactions as JSON
  Future<String> exportAsJSON() async {
    final transactions = await _getAllTransactions();
    final dateFormat = DateFormat('yyyy-MM-dd');

    final jsonData = transactions
        .map((transaction) => {
              'id': transaction.id,
              'title': transaction.title,
              'amount': transaction.amount,
              'date': dateFormat.format(transaction.date),
              'category': transaction.categoryName,
              'type': transaction.isExpense ? 'Expense' : 'Income',
              'paymentMethodOrSource': transaction.paymentMethodOrSource,
              'notes': transaction.notes,
            })
        .toList();

    // Save to file
    final file = await _saveToFile(jsonEncode(jsonData), 'transactions.json');
    return file.path;
  }

  /// Save data to a file in the downloads directory
  Future<File> _saveToFile(String data, String fileName) async {
    // Get the downloads directory
    final directory = await getExternalStorageDirectory() ??
        await getApplicationDocumentsDirectory();

    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);

    // Write the data to the file
    await file.writeAsString(data);
    return file;
  }

  /// Share the exported file
  Future<void> shareFile(String filePath) async {
    final file = XFile(filePath);
    await Share.shareXFiles([file], text: 'Expense App Transactions');
  }

  /// Escape CSV fields that contain commas, quotes, or newlines
  String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      // Escape quotes by doubling them and wrap the field in quotes
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
}
