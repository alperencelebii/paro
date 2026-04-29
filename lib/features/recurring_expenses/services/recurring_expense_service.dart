
import 'dart:convert';

import 'package:finance_track/features/recurring_expenses/models/recurring_expense_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class RecurringExpenseService {
  static const String _storageKey = 'paro_recurring_expenses_v1';
  static const Uuid _uuid = Uuid();

  Future<List<RecurringExpenseModel>> getRecurringExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(RecurringExpenseModel.fromJson)
          .where((item) => item.id.isNotEmpty)
          .toList()
        ..sort((a, b) => a.nextPaymentDate.compareTo(b.nextPaymentDate));
    } catch (_) {
      return [];
    }
  }

  Future<void> saveRecurringExpenses(List<RecurringExpenseModel> items) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(items.map((item) => item.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<RecurringExpenseModel> addRecurringExpense({
    required String title,
    required double amount,
    required String frequency,
    required DateTime nextPaymentDate,
    String category = 'Subscription',
  }) async {
    final items = await getRecurringExpenses();
    final model = RecurringExpenseModel(
      id: _uuid.v4(),
      title: title.trim(),
      amount: amount,
      frequency: frequency,
      nextPaymentDate: nextPaymentDate,
      category: category.trim().isEmpty ? 'Subscription' : category.trim(),
      createdAt: DateTime.now(),
    );
    await saveRecurringExpenses([...items, model]);
    return model;
  }

  Future<void> updateRecurringExpense(RecurringExpenseModel item) async {
    final items = await getRecurringExpenses();
    final next = items.map((current) {
      return current.id == item.id ? item : current;
    }).toList();
    await saveRecurringExpenses(next);
  }

  Future<void> deleteRecurringExpense(String id) async {
    final items = await getRecurringExpenses();
    await saveRecurringExpenses(items.where((item) => item.id != id).toList());
  }

  Future<double> monthlyEstimate() async {
    final items = await getRecurringExpenses();
    return items
        .where((item) => item.isActive)
        .fold<double>(0, (sum, item) => sum + item.monthlyEstimate);
  }

  Future<List<RecurringExpenseModel>> upcoming({int days = 7}) async {
    final items = await getRecurringExpenses();
    return items
        .where((item) => item.isActive && item.daysUntilDue <= days)
        .toList()
      ..sort((a, b) => a.daysUntilDue.compareTo(b.daysUntilDue));
  }
}
