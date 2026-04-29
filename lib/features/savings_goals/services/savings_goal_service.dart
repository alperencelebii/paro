
import 'dart:convert';

import 'package:finance_track/features/savings_goals/models/savings_goal_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class SavingsGoalService {
  static const String _storageKey = 'paro_savings_goals_v1';
  static const Uuid _uuid = Uuid();

  Future<List<SavingsGoalModel>> getGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(SavingsGoalModel.fromJson)
          .where((goal) => goal.id.isNotEmpty)
          .toList()
        ..sort((a, b) => b.progress.compareTo(a.progress));
    } catch (_) {
      return [];
    }
  }

  Future<void> saveGoals(List<SavingsGoalModel> goals) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(goals.map((goal) => goal.toJson()).toList()),
    );
  }

  Future<SavingsGoalModel> addGoal({
    required String title,
    required double targetAmount,
    double savedAmount = 0,
    DateTime? deadline,
  }) async {
    final goals = await getGoals();
    final goal = SavingsGoalModel(
      id: _uuid.v4(),
      title: title.trim(),
      targetAmount: targetAmount,
      savedAmount: savedAmount,
      deadline: deadline,
      createdAt: DateTime.now(),
    );
    await saveGoals([...goals, goal]);
    return goal;
  }

  Future<void> updateGoal(SavingsGoalModel goal) async {
    final goals = await getGoals();
    await saveGoals(
      goals.map((current) => current.id == goal.id ? goal : current).toList(),
    );
  }

  Future<void> deleteGoal(String id) async {
    final goals = await getGoals();
    await saveGoals(goals.where((goal) => goal.id != id).toList());
  }

  Future<void> addMoney(String id, double amount) async {
    final goals = await getGoals();
    await saveGoals(
      goals.map((goal) {
        if (goal.id != id) return goal;
        return goal.copyWith(
          savedAmount: (goal.savedAmount + amount).clamp(0.0, goal.targetAmount).toDouble(),
        );
      }).toList(),
    );
  }
}
