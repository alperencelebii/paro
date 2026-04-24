import 'package:finance_track/data/models/expense_model.dart';
import 'package:finance_track/data/models/income_model.dart';
import 'package:flutter/material.dart';

/// Unified transaction item for display
class TransactionItem {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final dynamic category;
  final String? notes;
  final bool isExpense;
  final Color categoryColor;
  final IconData categoryIcon;
  final String categoryName;
  final String? paymentMethodOrSource;

  TransactionItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    this.notes,
    required this.isExpense,
    required this.categoryColor,
    required this.categoryIcon,
    required this.categoryName,
    this.paymentMethodOrSource,
    String? extraInfo,
  });

  /// Create from an expense
  factory TransactionItem.fromExpense(Expense expense) {
    return TransactionItem(
      id: expense.uuid,
      title: expense.title,
      amount: expense.amount,
      date: expense.date,
      category: expense.category,
      notes: expense.notes,
      isExpense: true,
      categoryColor: expense.category.color,
      categoryIcon: expense.category.icon,
      categoryName: expense.category.displayName,
      paymentMethodOrSource: expense.paymentMethod,
    );
  }

  /// Create from an income
  factory TransactionItem.fromIncome(Income income) {
    return TransactionItem(
      id: income.uuid,
      title: income.title,
      amount: income.amount,
      date: income.date,
      category: income.category,
      notes: income.notes,
      isExpense: false,
      categoryColor: income.category.color,
      categoryIcon: income.category.icon,
      categoryName: income.category.displayName,
      paymentMethodOrSource: income.source,
    );
  }
}
