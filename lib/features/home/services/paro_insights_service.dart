
import 'dart:math' as math;

import 'package:finance_track/core/colors/app_colors.dart';
import 'package:finance_track/data/models/expense_model.dart';
import 'package:finance_track/data/models/income_model.dart';
import 'package:flutter/material.dart';

class ParoInsight {
  const ParoInsight({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color color;
}

class ParoInsightsService {
  const ParoInsightsService._();

  static List<ParoInsight> buildInsights({
    required List<Expense> expenses,
    required List<Income> incomes,
  }) {
    final now = DateTime.now();
    final currentExpenses = expenses.where((e) => _sameMonth(e.date, now)).toList();
    final previousMonth = DateTime(now.year, now.month - 1);
    final previousExpenses =
        expenses.where((e) => _sameMonth(e.date, previousMonth)).toList();

    final currentExpenseTotal = _sumExpenses(currentExpenses);
    final previousExpenseTotal = _sumExpenses(previousExpenses);
    final currentIncomeTotal =
        _sumIncomes(incomes.where((i) => _sameMonth(i.date, now)).toList());

    final insights = <ParoInsight>[];

    if (currentExpenses.isEmpty && incomes.isEmpty) {
      return const [
        ParoInsight(
          title: 'PARO hazır',
          message: 'İlk gelir veya giderini eklediğinde burada akıllı analizler görünecek.',
          icon: Icons.auto_awesome_rounded,
          color: AppColors.primary,
        ),
      ];
    }

    if (previousExpenseTotal > 0) {
      final change = ((currentExpenseTotal - previousExpenseTotal) / previousExpenseTotal) * 100;
      final isUp = change > 0;
      insights.add(
        ParoInsight(
          title: isUp ? 'Harcama artışı' : 'Daha kontrollü ay',
          message: isUp
              ? 'Bu ay geçen aya göre %${change.abs().toStringAsFixed(0)} daha fazla harcadın.'
              : 'Bu ay geçen aya göre %${change.abs().toStringAsFixed(0)} daha az harcadın. Güzel gidiyorsun.',
          icon: isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
          color: isUp ? AppColors.warning : AppColors.income,
        ),
      );
    }

    if (currentIncomeTotal > 0) {
      final spendRatio = currentExpenseTotal / currentIncomeTotal;
      insights.add(
        ParoInsight(
          title: spendRatio >= 0.85 ? 'Gelir-gider uyarısı' : 'Net durum iyi',
          message: spendRatio >= 0.85
              ? 'Bu ay gelirinin %${(spendRatio * 100).clamp(0, 999).toStringAsFixed(0)} kadarını harcadın.'
              : 'Bu ay gelirinin %${(spendRatio * 100).clamp(0, 999).toStringAsFixed(0)} kadarını harcadın.',
          icon: spendRatio >= 0.85
              ? Icons.warning_amber_rounded
              : Icons.verified_rounded,
          color: spendRatio >= 0.85 ? AppColors.expense : AppColors.income,
        ),
      );
    }

    final topCategory = _topCategory(currentExpenses);
    if (topCategory != null) {
      insights.add(
        ParoInsight(
          title: 'En yoğun kategori',
          message: 'Bu ay en çok ${topCategory.name} kategorisinde harcama yaptın.',
          icon: Icons.category_rounded,
          color: AppColors.primary,
        ),
      );
    }

    final lastSevenDaysTotal = _sumExpenses(
      expenses
          .where((e) => e.date.isAfter(now.subtract(const Duration(days: 7))))
          .toList(),
    );
    if (lastSevenDaysTotal > 0) {
      final average = lastSevenDaysTotal / 7;
      insights.add(
        ParoInsight(
          title: 'Son 7 gün',
          message: 'Son 7 gündeki günlük ortalama harcaman yaklaşık ${average.toStringAsFixed(0)}.',
          icon: Icons.calendar_month_rounded,
          color: AppColors.gradientStart,
        ),
      );
    }

    return insights.take(math.min(3, insights.length)).toList();
  }

  static List<double> dailyExpenseTrend(List<Expense> expenses, {int days = 7}) {
    final now = DateTime.now();
    final values = List<double>.filled(days, 0);
    for (final expense in expenses) {
      final diff = DateTime(now.year, now.month, now.day)
          .difference(DateTime(expense.date.year, expense.date.month, expense.date.day))
          .inDays;
      if (diff >= 0 && diff < days) {
        values[days - diff - 1] += expense.amount;
      }
    }
    return values;
  }

  static bool _sameMonth(DateTime date, DateTime target) =>
      date.year == target.year && date.month == target.month;

  static double _sumExpenses(List<Expense> expenses) =>
      expenses.fold(0, (sum, item) => sum + item.amount);

  static double _sumIncomes(List<Income> incomes) =>
      incomes.fold(0, (sum, item) => sum + item.amount);

  static _TopCategory? _topCategory(List<Expense> expenses) {
    if (expenses.isEmpty) return null;
    final totals = <String, double>{};
    for (final expense in expenses) {
      totals.update(
        expense.effectiveCategoryName,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return _TopCategory(entries.first.key, entries.first.value);
  }
}

class _TopCategory {
  const _TopCategory(this.name, this.amount);
  final String name;
  final double amount;
}
