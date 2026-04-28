// ignore_for_file: prefer_initializing_formals

import 'package:flutter/material.dart';
import 'package:objectbox/objectbox.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'user_category_model.dart';

/// Represents a category for an expense
enum ExpenseCategory {
  food,
  transportation,
  entertainment,
  utilities,
  shopping,
  health,
  education,
  travel,
  other,
}

/// Helper extensions for ExpenseCategory
extension ExpenseCategoryExtension on ExpenseCategory {
  /// Get a user-friendly name for the category
  String get displayName {
    switch (this) {
      case ExpenseCategory.food:
        return 'Food & Dining';
      case ExpenseCategory.transportation:
        return 'Transportation';
      case ExpenseCategory.entertainment:
        return 'Entertainment';
      case ExpenseCategory.utilities:
        return 'Utilities';
      case ExpenseCategory.shopping:
        return 'Shopping';
      case ExpenseCategory.health:
        return 'Health';
      case ExpenseCategory.education:
        return 'Education';
      case ExpenseCategory.travel:
        return 'Travel';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  /// Get the icon associated with this category
  IconData get icon {
    switch (this) {
      case ExpenseCategory.food:
        return Icons.restaurant;
      case ExpenseCategory.transportation:
        return Icons.directions_car;
      case ExpenseCategory.entertainment:
        return Icons.movie;
      case ExpenseCategory.utilities:
        return Icons.home;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag;
      case ExpenseCategory.health:
        return Icons.medical_services;
      case ExpenseCategory.education:
        return Icons.school;
      case ExpenseCategory.travel:
        return Icons.flight;
      case ExpenseCategory.other:
        return Icons.miscellaneous_services;
    }
  }

  /// Get the color associated with this category
  Color get color {
    switch (this) {
      case ExpenseCategory.food:
        return Colors.redAccent;
      case ExpenseCategory.transportation:
        return Colors.blueAccent;
      case ExpenseCategory.entertainment:
        return Colors.purpleAccent;
      case ExpenseCategory.utilities:
        return Colors.orangeAccent;
      case ExpenseCategory.shopping:
        return Colors.greenAccent.shade700;
      case ExpenseCategory.health:
        return Colors.pinkAccent;
      case ExpenseCategory.education:
        return Colors.tealAccent.shade700;
      case ExpenseCategory.travel:
        return Colors.amberAccent;
      case ExpenseCategory.other:
        return Colors.blueGrey;
    }
  }

  /// Convert to JSON (returns the enum index)
  int toJson() => index;

  /// Create from JSON
  static ExpenseCategory fromJson(int index) =>
      ExpenseCategory.values[index.clamp(0, ExpenseCategory.values.length - 1)];
}

/// Expense model class
@Entity()
class Expense {
  // ObjectBox ID
  @Id()
  int? id;

  // UUID used as a business ID
  @Index()
  String uuid = '';

  String title = '';
  double amount = 0.0;

  // Store the date and time details
  @Property(type: PropertyType.date)
  DateTime date = DateTime.now();

  // Store the category as an integer (enum index)
  int categoryIndex = 0;

  // Optional custom category fields (for user-defined categories)
  String? customCategoryUuid;
  String? customCategoryName;
  int? customCategoryColorValue;
  int? customCategoryIconCodePoint;
  String? customCategoryIconFontFamily;

  String? notes;
  String paymentMethod = '';

  // Store creation timestamp
  @Property(type: PropertyType.date)
  DateTime createdAt = DateTime.now();

  /// No-args constructor for ObjectBox
  Expense();

  /// Constructor for creating a new expense
  Expense.create({
    required String uuid,
    required String title,
    required double amount,
    required DateTime date,
    required ExpenseCategory category,
    String? notes,
    required String paymentMethod,
    DateTime? createdAt,
    String? customCategoryUuid,
    String? customCategoryName,
    int? customCategoryColorValue,
    int? customCategoryIconCodePoint,
    String? customCategoryIconFontFamily,
  }) {
    this.uuid = uuid;
    this.title = title;
    this.amount = amount;
    this.date = date;
    categoryIndex = category.index;
    this.notes = notes;
    this.paymentMethod = paymentMethod;
    this.createdAt = createdAt ?? DateTime.now();
    this.customCategoryUuid = customCategoryUuid;
    this.customCategoryName = customCategoryName;
    this.customCategoryColorValue = customCategoryColorValue;
    this.customCategoryIconCodePoint = customCategoryIconCodePoint;
    this.customCategoryIconFontFamily = customCategoryIconFontFamily;
  }

  /// Get the category enum from the stored index
  @Transient()
  ExpenseCategory get category => ExpenseCategory.values[categoryIndex];

  // Whether this expense uses a custom category
  @Transient()
  bool get usesCustomCategory => customCategoryUuid != null;

  @Transient()
  String get effectiveCategoryName => usesCustomCategory
      ? (customCategoryName ?? 'Other')
      : category.displayName;

  @Transient()
  IconData get effectiveCategoryIcon => usesCustomCategory
      ? (CategoryIconResolver.fromCodePoint(customCategoryIconCodePoint) ?? Icons.category)
      : category.icon;

  @Transient()
  Color get effectiveCategoryColor => usesCustomCategory
      ? Color(customCategoryColorValue ?? Colors.blueGrey.value)
      : category.color;

  /// Create a copy with updated fields
  Expense copyWith({
    String? uuid,
    String? title,
    double? amount,
    DateTime? date,
    ExpenseCategory? category,
    String? notes,
    String? paymentMethod,
    DateTime? createdAt,
    String? customCategoryUuid,
    String? customCategoryName,
    int? customCategoryColorValue,
    int? customCategoryIconCodePoint,
    String? customCategoryIconFontFamily,
  }) {
    final result = Expense()
      ..id = id
      ..uuid = uuid ?? this.uuid
      ..title = title ?? this.title
      ..amount = amount ?? this.amount
      ..date = date ?? this.date
      ..categoryIndex = category != null ? category.index : categoryIndex
      ..notes = notes ?? this.notes
      ..paymentMethod = paymentMethod ?? this.paymentMethod
      ..createdAt = createdAt ?? this.createdAt
      ..customCategoryUuid = customCategoryUuid ?? this.customCategoryUuid
      ..customCategoryName = customCategoryName ?? this.customCategoryName
      ..customCategoryColorValue =
          customCategoryColorValue ?? this.customCategoryColorValue
      ..customCategoryIconCodePoint =
          customCategoryIconCodePoint ?? this.customCategoryIconCodePoint
      ..customCategoryIconFontFamily =
          customCategoryIconFontFamily ?? this.customCategoryIconFontFamily;

    return result;
  }

  /// Factory constructor to create an Expense from a Map
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense.create(
      uuid: map['uuid'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: (map['date'] as firestore.Timestamp).toDate(),
      category: ExpenseCategory
          .values[(map['categoryIndex'] ?? map['category_index'] ?? 0) as int],
      notes: map['notes'] as String?,
      paymentMethod: map['paymentMethod'] as String,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as firestore.Timestamp).toDate()
          : null,
      customCategoryUuid: map['customCategoryUuid'] as String?,
      customCategoryName: map['customCategoryName'] as String?,
      customCategoryColorValue: (map['customCategoryColorValue'] as int?),
      customCategoryIconCodePoint: (map['customCategoryIconCodePoint'] as int?),
      customCategoryIconFontFamily:
          map['customCategoryIconFontFamily'] as String?,
    );
  }
}
