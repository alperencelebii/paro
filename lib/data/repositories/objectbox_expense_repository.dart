// import '../models/expense_model.dart';
import 'package:finance_track/data/models/expense_model.dart';

import '../objectbox.dart';
import '../../objectbox.g.dart'; // Import generated code for queries
import 'expense_repository.dart';

/// Implementation of ExpenseRepository that uses ObjectBox for storage
class ObjectBoxExpenseRepository implements ExpenseRepository {
  final ObjectBox _objectBox;

  /// Constructor taking an ObjectBox instance
  ObjectBoxExpenseRepository(this._objectBox);

  Stream<List<Expense>> getExpensesStream() {
    // We don't have built-in streaming with ObjectBox, so we'll manually
    // poll for changes and emit them through a stream controller
    return Stream.periodic(
      const Duration(seconds: 1),
      (_) => getExpenses(),
    ).asyncMap((future) => future);
  }

  @override
  Future<List<Expense>> getExpenses() async {
    // Create query for expenses with amount > 0 and order by date descending
    final queryBuilder = _objectBox.expenseBox
        .query(Expense_.amount.greaterThan(0))
      ..order(Expense_.date, flags: Order.descending);

    final query = queryBuilder.build();
    // Find the expenses and close the query
    final expenses = query.find();
    query.close();

    return expenses;
  }

  @override
  Future<Expense> getExpenseById(String id) async {
    // Query for expenses with matching UUID
    final queryBuilder = _objectBox.expenseBox.query(Expense_.uuid.equals(id));
    final query = queryBuilder.build();
    final expenses = query.find();
    query.close();

    if (expenses.isEmpty) {
      throw Exception('Expense not found: $id');
    }

    return expenses.first;
  }

  @override
  Future<void> addExpense(Expense expense) async {
    // Add the expense to the box
    _objectBox.expenseBox.put(expense);
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    // Update the expense in the box
    _objectBox.expenseBox.put(expense);
  }

  @override
  Future<void> deleteExpense(String uuid) async {
    // Query for expenses with matching UUID
    final queryBuilder =
        _objectBox.expenseBox.query(Expense_.uuid.equals(uuid));
    final query = queryBuilder.build();
    final expenses = query.find();
    query.close();

    if (expenses.isEmpty) {
      throw Exception('Expense not found: $uuid');
    }

    // Remove the expense from the box
    _objectBox.expenseBox.remove(expenses.first.id!);
  }

  /// Clears all expenses from the local database
  Future<void> clearAllExpenses() async {
    try {
      _objectBox.expenseBox.removeAll();
    } catch (e) {
      throw Exception('Failed to clear expenses: $e');
    }
  }

  @override
  Future<List<Expense>> getExpensesByCategory(ExpenseCategory category) async {
    // Query for expenses with matching category index and order by date
    final queryBuilder = _objectBox.expenseBox
        .query(Expense_.categoryIndex.equals(category.index))
      ..order(Expense_.date, flags: Order.descending);

    final query = queryBuilder.build();
    final filteredExpenses = query.find();
    query.close();

    return filteredExpenses;
  }

  @override
  Future<List<Expense>> getAllExpenses() async {
    // Query all expenses ordered by date descending
    final queryBuilder = _objectBox.expenseBox.query()
      ..order(Expense_.date, flags: Order.descending);

    final query = queryBuilder.build();
    final expenses = query.find();
    query.close();

    return expenses;
  }

  @override
  void dispose() {
    // Nothing to dispose
  }

  Future<List<Expense>> getExpensesByDate(DateTime date) async {
    // Create start and end dates for the day
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

    return getExpensesByDateRange(startOfDay, endOfDay);
  }

  Future<List<Expense>> getExpensesByDateRange(
      DateTime start, DateTime end) async {
    // Query for expenses within the date range
    final queryBuilder = _objectBox.expenseBox.query(
      Expense_.date.between(
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ),
    )..order(Expense_.date, flags: Order.descending);

    final query = queryBuilder.build();
    final expenses = query.find();
    query.close();

    return expenses;
  }

  Future<double> getTotalExpenseAmount() async {
    // Get all expenses
    final expenses = await getAllExpenses();

    // Sum up the amounts
    return expenses.fold<double>(
        0.0, (total, expense) => total + expense.amount);
  }
}
