import '../models/income_model.dart';
import '../objectbox.dart';
import '../../objectbox.g.dart'; // Import generated code for queries
import 'income_repository.dart';

/// Implementation of IncomeRepository that uses ObjectBox for storage
class ObjectBoxIncomeRepository implements IncomeRepository {
  final ObjectBox _objectBox;

  /// Constructor taking an ObjectBox instance
  ObjectBoxIncomeRepository(this._objectBox);

  @override
  Stream<List<Income>> getIncomesStream() {
    // We don't have built-in streaming with ObjectBox, so we'll manually
    // poll for changes and emit them through a stream controller
    return Stream.periodic(
      const Duration(seconds: 1),
      (_) => getIncomes(),
    ).asyncMap((future) => future);
  }

  @override
  Future<List<Income>> getIncomes() async {
    // Create query for incomes with amount > 0 and order by date descending
    final queryBuilder = _objectBox.incomeBox
        .query(Income_.amount.greaterThan(0))
      ..order(Income_.date, flags: Order.descending);

    final query = queryBuilder.build();
    // Find the incomes and close the query
    final incomes = query.find();
    query.close();

    return incomes;
  }

  @override
  Future<Income> getIncomeById(String id) async {
    // Query for incomes with matching UUID
    final queryBuilder = _objectBox.incomeBox.query(Income_.uuid.equals(id));
    final query = queryBuilder.build();
    final incomes = query.find();
    query.close();

    if (incomes.isEmpty) {
      throw Exception('Income not found: $id');
    }

    return incomes.first;
  }

  @override
  Future<void> addIncome(Income income) async {
    // Add the income to the box
    _objectBox.incomeBox.put(income);
  }

  @override
  Future<void> updateIncome(Income income) async {
    // Update the income in the box
    _objectBox.incomeBox.put(income);
  }

  @override
  Future<void> deleteIncome(String uuid) async {
    // Query for incomes with matching UUID
    final queryBuilder = _objectBox.incomeBox.query(Income_.uuid.equals(uuid));
    final query = queryBuilder.build();
    final incomes = query.find();
    query.close();

    if (incomes.isEmpty) {
      throw Exception('Income not found: $uuid');
    }

    // Remove the income from the box
    _objectBox.incomeBox.remove(incomes.first.id!);
  }

  /// Clears all incomes from the local database
  Future<void> clearAllIncomes() async {
    try {
      _objectBox.incomeBox.removeAll();
    } catch (e) {
      throw Exception('Failed to clear incomes: $e');
    }
  }

  @override
  Future<List<Income>> getIncomesByCategory(IncomeCategory category) async {
    // Query for incomes with matching category index and order by date
    final queryBuilder = _objectBox.incomeBox
        .query(Income_.categoryIndex.equals(category.index))
      ..order(Income_.date, flags: Order.descending);

    final query = queryBuilder.build();
    final filteredIncomes = query.find();
    query.close();

    return filteredIncomes;
  }

  @override
  Future<List<Income>> getAllIncomes() async {
    // Query all incomes ordered by date descending
    final queryBuilder = _objectBox.incomeBox.query()
      ..order(Income_.date, flags: Order.descending);

    final query = queryBuilder.build();
    final incomes = query.find();
    query.close();

    return incomes;
  }

  @override
  void dispose() {
    // Nothing to dispose
  }
}
