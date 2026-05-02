import 'dart:math' as math;

import 'package:finance_track/core/colors/app_colors.dart';
import 'package:finance_track/data/models/expense_model.dart';
import 'package:finance_track/data/models/income_model.dart';
import 'package:flutter/material.dart';

class ParoComfortCardData {
  const ParoComfortCardData({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    this.actionLabel,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final String? actionLabel;
}

class ParoGentleNotification {
  const ParoGentleNotification({
    required this.title,
    required this.message,
    required this.icon,
    required this.priority,
  });

  final String title;
  final String message;
  final IconData icon;
  final int priority;
}

class ParoQuickAddSuggestion {
  const ParoQuickAddSuggestion({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  final String label;
  final double amount;
  final IconData icon;
  final Color color;
}

class ParoCalmCoachService {
  const ParoCalmCoachService._();

  static ParoComfortCardData dailyStatus({
    required List<Expense> expenses,
    required List<Income> incomes,
  }) {
    final now = DateTime.now();
    final todayExpense = _sumExpenses(
      expenses.where((item) => _sameDay(item.date, now)).toList(),
    );
    final monthExpense = _sumExpenses(
      expenses.where((item) => _sameMonth(item.date, now)).toList(),
    );
    final monthIncome = _sumIncomes(
      incomes.where((item) => _sameMonth(item.date, now)).toList(),
    );

    if (expenses.isEmpty && incomes.isEmpty) {
      return const ParoComfortCardData(
        title: 'Sakin başlangıç',
        message: 'İlk işlemini eklediğinde PARO sana yormadan özet ve öneriler gösterecek.',
        icon: Icons.spa_rounded,
        color: AppColors.primary,
        actionLabel: 'İlk işlemimi ekle',
      );
    }

    if (todayExpense == 0) {
      return const ParoComfortCardData(
        title: 'Bugün tertemiz',
        message: 'Bugün henüz harcama görünmüyor. Gün içinde bir şey eklersen tek dokunuşla kaydedebilirsin.',
        icon: Icons.verified_rounded,
        color: AppColors.income,
        actionLabel: 'Hızlı ekle',
      );
    }

    if (monthIncome > 0) {
      final ratio = monthExpense / monthIncome;
      if (ratio >= 0.90) {
        return const ParoComfortCardData(
          title: 'Biraz yavaşlamak iyi gelebilir',
          message: 'Bu ay harcamaların gelirine yaklaştı. Küçük seçimlerle ayı daha rahat kapatabilirsin.',
          icon: Icons.favorite_rounded,
          color: AppColors.warning,
          actionLabel: 'Önerilere bak',
        );
      }
      if (ratio <= 0.55) {
        return const ParoComfortCardData(
          title: 'Rahat gidiyorsun',
          message: 'Bu ay dengeli görünüyorsun. Böyle devam edersen ay sonu daha kontrollü olur.',
          icon: Icons.self_improvement_rounded,
          color: AppColors.income,
          actionLabel: 'Detayları gör',
        );
      }
    }

    return ParoComfortCardData(
      title: 'Bugünün özeti hazır',
      message: 'Bugün ${todayExpense.toStringAsFixed(0)} tutarında harcama kaydın var. Kontrol sende, acele yok.',
      icon: Icons.lightbulb_rounded,
      color: AppColors.primary,
      actionLabel: 'Hızlı ekle',
    );
  }

  static List<ParoComfortCardData> suggestions({
    required List<Expense> expenses,
    required List<Income> incomes,
  }) {
    final now = DateTime.now();
    final monthExpenses = expenses.where((item) => _sameMonth(item.date, now)).toList();
    final monthIncomes = incomes.where((item) => _sameMonth(item.date, now)).toList();
    final totalExpense = _sumExpenses(monthExpenses);
    final totalIncome = _sumIncomes(monthIncomes);
    final items = <ParoComfortCardData>[];

    final topCategory = _topCategory(monthExpenses);
    if (topCategory != null) {
      items.add(
        ParoComfortCardData(
          title: 'Küçük öneri',
          message: '${topCategory.name} harcamalarında haftada bir küçük azaltma ay sonunda fark yaratabilir.',
          icon: Icons.tips_and_updates_rounded,
          color: AppColors.gradientStart,
          actionLabel: 'Not aldım',
        ),
      );
    }

    if (totalIncome > 0) {
      final savingPotential = math.max(totalIncome - totalExpense, 0);
      if (savingPotential > 0) {
        items.add(
          ParoComfortCardData(
            title: 'Birikim alanı',
            message: 'Bu ay yaklaşık ${savingPotential.toStringAsFixed(0)} tutarında nefes alanın var. İstersen bunu hedefe çevirebilirsin.',
            icon: Icons.savings_rounded,
            color: AppColors.income,
            actionLabel: 'Hedef oluştur',
          ),
        );
      } else {
        items.add(const ParoComfortCardData(
          title: 'Denge zamanı',
          message: 'Bu ay gelir-gider dengesi sıkışmış görünüyor. Önce küçük harcamaları kontrol etmek yeterli olabilir.',
          icon: Icons.balance_rounded,
          color: AppColors.warning,
          actionLabel: 'Sakin plan yap',
        ));
      }
    }

    if (expenses.length < 3) {
      items.add(const ParoComfortCardData(
        title: 'Kolay takip',
        message: 'Günde 10 saniyelik kayıt, ay sonunda çok daha net bir tablo verir.',
        icon: Icons.touch_app_rounded,
        color: AppColors.primary,
        actionLabel: 'Tek dokunuşla ekle',
      ));
    }

    return items.isEmpty
        ? const [
            ParoComfortCardData(
              title: 'PARO yanında',
              message: 'Veri ekledikçe daha kişisel, yumuşak ve kullanışlı öneriler burada görünecek.',
              icon: Icons.auto_awesome_rounded,
              color: AppColors.primary,
              actionLabel: 'Devam et',
            ),
          ]
        : items.take(3).toList();
  }

  static List<ParoGentleNotification> gentleNotifications({
    required List<Expense> expenses,
    required List<Income> incomes,
  }) {
    final now = DateTime.now();
    final notes = <ParoGentleNotification>[];
    final todayExpense = _sumExpenses(expenses.where((e) => _sameDay(e.date, now)).toList());
    final lastSeven = _sumExpenses(
      expenses.where((e) => e.date.isAfter(now.subtract(const Duration(days: 7)))).toList(),
    );
    final previousSeven = _sumExpenses(
      expenses.where((e) =>
          e.date.isBefore(now.subtract(const Duration(days: 7))) &&
          e.date.isAfter(now.subtract(const Duration(days: 14)))).toList(),
    );

    if (todayExpense == 0) {
      notes.add(const ParoGentleNotification(
        title: 'Günlük kontrol',
        message: 'Bugün bir harcama olduysa kaydetmek için iyi bir an.',
        icon: Icons.edit_note_rounded,
        priority: 1,
      ));
    }

    if (previousSeven > 0 && lastSeven < previousSeven) {
      notes.add(const ParoGentleNotification(
        title: 'Güzel ilerleme',
        message: 'Bu hafta geçen haftadan daha sakin görünüyor. Böyle devam.',
        icon: Icons.celebration_rounded,
        priority: 0,
      ));
    }

    final monthIncome = _sumIncomes(incomes.where((i) => _sameMonth(i.date, now)).toList());
    final monthExpense = _sumExpenses(expenses.where((e) => _sameMonth(e.date, now)).toList());
    if (monthIncome > 0 && monthExpense / monthIncome > 0.85) {
      notes.add(const ParoGentleNotification(
        title: 'Nazik bütçe uyarısı',
        message: 'Bu ay harcamaların biraz yükseldi. İstersen küçük bir denge planı yapabiliriz.',
        icon: Icons.notifications_active_rounded,
        priority: 2,
      ));
    }

    notes.sort((a, b) => a.priority.compareTo(b.priority));
    return notes.take(2).toList();
  }

  static List<ParoQuickAddSuggestion> quickAdds(List<Expense> expenses) {
    final recent = expenses.take(30).toList();
    final avg = recent.isEmpty
        ? 0.0
        : recent.fold<double>(0, (sum, item) => sum + item.amount) / recent.length;

    final base = avg <= 0 ? 100.0 : avg;
    return [
      ParoQuickAddSuggestion(
        label: 'Kahve',
        amount: _roundToFriendly(base * 0.35),
        icon: Icons.local_cafe_rounded,
        color: AppColors.warning,
      ),
      ParoQuickAddSuggestion(
        label: 'Market',
        amount: _roundToFriendly(base * 1.25),
        icon: Icons.shopping_basket_rounded,
        color: AppColors.income,
      ),
      ParoQuickAddSuggestion(
        label: 'Ulaşım',
        amount: _roundToFriendly(base * 0.55),
        icon: Icons.directions_bus_rounded,
        color: AppColors.primary,
      ),
    ];
  }

  static int financialComfortScore({
    required List<Expense> expenses,
    required List<Income> incomes,
  }) {
    final now = DateTime.now();
    final monthExpense = _sumExpenses(expenses.where((e) => _sameMonth(e.date, now)).toList());
    final monthIncome = _sumIncomes(incomes.where((i) => _sameMonth(i.date, now)).toList());
    if (monthIncome <= 0 && monthExpense <= 0) return 70;
    if (monthIncome <= 0) return 45;
    final ratio = (monthExpense / monthIncome).clamp(0, 1.4);
    final score = 100 - (ratio * 55).round();
    final consistencyBonus = expenses.where((e) => e.date.isAfter(now.subtract(const Duration(days: 7)))).length >= 3 ? 8 : 0;
    return (score + consistencyBonus).clamp(35, 98).toInt();
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool _sameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  static double _sumExpenses(List<Expense> expenses) =>
      expenses.fold(0, (sum, item) => sum + item.amount);

  static double _sumIncomes(List<Income> incomes) =>
      incomes.fold(0, (sum, item) => sum + item.amount);

  static double _roundToFriendly(double value) {
    if (value < 50) return 50.0;
    if (value < 150) return ((value / 10).round() * 10).toDouble();
    return ((value / 50).round() * 50).toDouble();
  }

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
  const _TopCategory(this.name, this.total);
  final String name;
  final double total;
}
