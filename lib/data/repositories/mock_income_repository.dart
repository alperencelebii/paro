import 'dart:async';
import 'package:uuid/uuid.dart';

import '../models/income_model.dart';
import 'income_repository.dart';

/// Mock implementation of IncomeRepository for testing and fallback
class MockIncomeRepository implements IncomeRepository {
  final List<Income> _incomes = [];
  final _streamController = StreamController<List<Income>>.broadcast();

  /// Constructor with optional initial incomes
  MockIncomeRepository() {
    // Add some sample incomes for demo purposes
    _addSampleIncomes();
  }

  void _addSampleIncomes() {
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;

    // Add current month income
    _incomes.addAll([
      // Main salary for current month
      Income.create(
        uuid: const Uuid().v4(),
        title: 'Monthly Salary',
        amount: 320000.00,
        date: DateTime(currentYear, currentMonth, 5),
        category: IncomeCategory.salary,
        notes: 'April salary',
        source: 'ABC Company',
      ),

      // Bonus for current month
      Income.create(
        uuid: const Uuid().v4(),
        title: 'Performance Bonus',
        amount: 50000.00,
        date: DateTime(currentYear, currentMonth, 7),
        category: IncomeCategory.salary,
        notes: 'Quarterly performance bonus',
        source: 'ABC Company',
      ),

      // Freelance income for current month
      Income.create(
        uuid: const Uuid().v4(),
        title: 'Freelance Project',
        amount: 23500.00,
        date: DateTime(currentYear, currentMonth, 10),
        category: IncomeCategory.freelance,
        notes: 'Website development',
        source: 'XYZ Client',
      ),

      // Previous month income
      Income.create(
        uuid: const Uuid().v4(),
        title: 'Previous Salary',
        amount: 320000.00,
        date: DateTime(currentYear, currentMonth - 1, 5),
        category: IncomeCategory.salary,
        notes: 'Previous month salary',
        source: 'ABC Company',
      ),

      Income.create(
        uuid: const Uuid().v4(),
        title: 'Dividend',
        amount: 12550.00,
        date: DateTime(currentYear, currentMonth - 1, 15),
        category: IncomeCategory.investment,
        notes: 'Quarterly dividend',
        source: 'Stock Portfolio',
      ),
    ]);

    // Emit the initial incomes
    _streamController.add(_incomes);
  }

  @override
  Future<List<Income>> getIncomes() async {
    return _incomes;
  }

  @override
  Stream<List<Income>> getIncomesStream() {
    return _streamController.stream;
  }

  @override
  Future<Income> getIncomeById(String id) async {
    final income = _incomes.firstWhere(
      (income) => income.uuid == id,
      orElse: () => throw Exception('Income not found: $id'),
    );
    return income;
  }

  @override
  Future<void> addIncome(Income income) async {
    _incomes.add(income);
    _streamController.add(_incomes);
  }

  @override
  Future<void> updateIncome(Income income) async {
    final index = _incomes.indexWhere((e) => e.uuid == income.uuid);
    if (index != -1) {
      _incomes[index] = income;
      _streamController.add(_incomes);
    } else {
      throw Exception('Income not found: ${income.uuid}');
    }
  }

  @override
  Future<void> deleteIncome(String id) async {
    final index = _incomes.indexWhere((e) => e.uuid == id);
    if (index != -1) {
      _incomes.removeAt(index);
      _streamController.add(_incomes);
    } else {
      throw Exception('Income not found: $id');
    }
  }

  @override
  Future<List<Income>> getIncomesByCategory(IncomeCategory category) async {
    return _incomes.where((income) => income.category == category).toList();
  }

  @override
  Future<List<Income>> getAllIncomes() async {
    // Return all incomes
    return _incomes;
  }

  @override
  void dispose() {
    _streamController.close();
  }
}
