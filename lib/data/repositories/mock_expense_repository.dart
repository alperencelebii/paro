import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/expense_model.dart';
import 'expense_repository.dart';

/// A mock implementation of ExpenseRepository that stores expenses in memory
/// Used as a fallback when ObjectBox fails to initialize
class MockExpenseRepository implements ExpenseRepository {
  final List<Expense> _expenses = [];
  final _controller = StreamController<List<Expense>>.broadcast();

  MockExpenseRepository() {
    // Add some sample expenses
    _addSampleExpenses();
  }

  void _addSampleExpenses() {
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;

    // Add realistic current month expenses
    // Major expense from current month
    addExpense(
      Expense.create(
        uuid: const Uuid().v4(),
        title: 'Rent Payment',
        amount: 45000.00,
        date: DateTime(currentYear, currentMonth, 5),
        category: ExpenseCategory.utilities,
        paymentMethod: 'Bank Transfer',
        notes: 'Monthly rent',
      ),
    );

    // Groceries current month
    addExpense(
      Expense.create(
        uuid: const Uuid().v4(),
        title: 'Groceries',
        amount: 12500.00,
        date: DateTime(currentYear, currentMonth, 8),
        category: ExpenseCategory.food,
        paymentMethod: 'Credit Card',
        notes: 'Weekly grocery shopping',
      ),
    );

    // Dining out current month
    addExpense(
      Expense.create(
        uuid: const Uuid().v4(),
        title: 'Restaurant Dinner',
        amount: 3500.00,
        date: DateTime(currentYear, currentMonth, 10),
        category: ExpenseCategory.food,
        paymentMethod: 'Credit Card',
        notes: 'Family dinner',
      ),
    );

    // Transportation current month
    addExpense(
      Expense.create(
        uuid: const Uuid().v4(),
        title: 'Fuel',
        amount: 8500.00,
        date: DateTime(currentYear, currentMonth, 6),
        category: ExpenseCategory.transportation,
        paymentMethod: 'Debit Card',
        notes: 'Monthly fuel expense',
      ),
    );

    // Add a few older expenses from last month
    addExpense(
      Expense.create(
        uuid: const Uuid().v4(),
        title: 'Movie Tickets',
        amount: 2500.00,
        date: DateTime(currentYear, currentMonth - 1, 20),
        category: ExpenseCategory.entertainment,
        paymentMethod: 'Debit Card',
        notes: 'Weekend movie',
      ),
    );

    addExpense(
      Expense.create(
        uuid: const Uuid().v4(),
        title: 'Previous Rent',
        amount: 45000.00,
        date: DateTime(currentYear, currentMonth - 1, 5),
        category: ExpenseCategory.utilities,
        paymentMethod: 'Bank Transfer',
        notes: 'Last month rent',
      ),
    );
  }

  Stream<List<Expense>> getExpensesStream() {
    _controller.add(_expenses);
    return _controller.stream;
  }

  @override
  Future<List<Expense>> getExpenses() async {
    return _expenses;
  }

  @override
  Future<Expense> getExpenseById(String id) async {
    final expense = _expenses.firstWhere(
      (e) => e.uuid == id,
      orElse: () => throw Exception('Expense not found: $id'),
    );
    return expense;
  }

  @override
  Future<void> addExpense(Expense expense) async {
    _expenses.add(expense);
    _controller.add(_expenses);
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    final index = _expenses.indexWhere((e) => e.uuid == expense.uuid);
    if (index != -1) {
      _expenses[index] = expense;
      _controller.add(_expenses);
    }
  }

  @override
  Future<void> deleteExpense(String uuid) async {
    _expenses.removeWhere((expense) => expense.uuid == uuid);
    _controller.add(_expenses);
  }

  @override
  Future<List<Expense>> getExpensesByCategory(ExpenseCategory category) async {
    final filteredExpenses =
        _expenses.where((expense) => expense.category == category).toList();
    return filteredExpenses;
  }

  @override
  Future<List<Expense>> getAllExpenses() async {
    // Return all expenses
    return _expenses;
  }

  @override
  void dispose() {
    _controller.close();
  }
}
