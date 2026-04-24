import '../models/budget_model.dart';
import 'firebase_budget_repository.dart';
import 'objectbox_budget_repository.dart';

/// Offline-first Budget repository: writes to local immediately and
/// mirrors to Firebase when possible.
class CompositeBudgetRepository {
  final ObjectBoxBudgetRepository _local;
  final FirebaseBudgetRepository _cloud;

  CompositeBudgetRepository({
    required ObjectBoxBudgetRepository local,
    required FirebaseBudgetRepository cloud,
  })  : _local = local,
        _cloud = cloud;

  Budget? getActiveBudget() => _local.getActiveBudget();

  List<Budget> getAllBudgets() => _local.getAllBudgets();

  Budget createBudget({
    required double amount,
    required BudgetPeriod period,
    required DateTime startDate,
    DateTime? endDate,
    String title = '',
  }) {
    final b = _local.createBudget(
      amount: amount,
      periodIndex: period.index,
      startDate: startDate,
      endDate: endDate,
      title: title,
    );
    // Fire-and-forget cloud upsert
    _cloud.upsert(b).catchError((_) {});
    return b;
  }

  Budget updateBudget(Budget budget) {
    final updated = _local.updateBudget(budget);
    _cloud.upsert(updated).catchError((_) {});
    return updated;
  }

  bool deleteBudget(int id) {
    // Find the budget locally to know its uuid for cloud deletion
    final budgets = _local.getAllBudgets();
    final target = budgets.firstWhere(
      (b) => b.id == id,
      orElse: () => Budget(),
    );

    final success = _local.deleteBudget(id);

    if (success && target.uuid.isNotEmpty) {
      _cloud.remove(target.uuid).catchError((_) {});
    }

    return success;
  }

  Budget setActiveBudget(int id) {
    final b = _local.setActiveBudget(id);
    _cloud.upsert(b).catchError((_) {});
    return b;
  }
}
