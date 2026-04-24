// ignore_for_file: public_member_api_docs, sort_constructors_first, prefer_initializing_formals

import 'package:flutter/material.dart';
import 'package:objectbox/objectbox.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

/// Represents a category for an income
enum IncomeCategory {
  salary,
  freelance,
  business,
  investment,
  rental,
  gift,
  refund,
  other,
}

/// Extension on IncomeCategory to provide display names and icons
extension IncomeCategoryX on IncomeCategory {
  String get displayName {
    switch (this) {
      case IncomeCategory.salary:
        return 'Salary';
      case IncomeCategory.freelance:
        return 'Freelance';
      case IncomeCategory.business:
        return 'Business';
      case IncomeCategory.investment:
        return 'Investment';
      case IncomeCategory.rental:
        return 'Rental';
      case IncomeCategory.gift:
        return 'Gift';
      case IncomeCategory.refund:
        return 'Refund';
      case IncomeCategory.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case IncomeCategory.salary:
        return Icons.work;
      case IncomeCategory.freelance:
        return Icons.computer;
      case IncomeCategory.business:
        return Icons.business;
      case IncomeCategory.investment:
        return Icons.trending_up;
      case IncomeCategory.rental:
        return Icons.home;
      case IncomeCategory.gift:
        return Icons.card_giftcard;
      case IncomeCategory.refund:
        return Icons.undo;
      case IncomeCategory.other:
        return Icons.category;
    }
  }

  Color get color {
    switch (this) {
      case IncomeCategory.salary:
        return Colors.green;
      case IncomeCategory.freelance:
        return Colors.blue;
      case IncomeCategory.business:
        return Colors.purple;
      case IncomeCategory.investment:
        return Colors.amber;
      case IncomeCategory.rental:
        return Colors.orange;
      case IncomeCategory.gift:
        return Colors.pink;
      case IncomeCategory.refund:
        return Colors.teal;
      case IncomeCategory.other:
        return Colors.grey;
    }
  }

  /// Convert to JSON (returns the enum index)
  int toJson() => index;

  /// Create from JSON
  static IncomeCategory fromJson(int index) =>
      IncomeCategory.values[index.clamp(0, IncomeCategory.values.length - 1)];
}

/// Income model class
@Entity()
class Income {
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

  String? notes;
  String source = ''; // Source of income (employer, client, etc.)

  // Store creation timestamp
  @Property(type: PropertyType.date)
  DateTime createdAt = DateTime.now();

  /// No-args constructor for ObjectBox
  Income();

  /// Constructor for creating a new income
  Income.create({
    required String uuid,
    required String title,
    required double amount,
    required DateTime date,
    required IncomeCategory category,
    String? notes,
    required String source,
    DateTime? createdAt,
  }) {
    this.uuid = uuid;
    this.title = title;
    this.amount = amount;
    this.date = date;
    categoryIndex = category.index;
    this.notes = notes;
    this.source = source;
    this.createdAt = createdAt ?? DateTime.now();
  }

  /// Get the category enum from the stored index
  @Transient()
  IncomeCategory get category => IncomeCategory.values[categoryIndex];

  /// Create a copy with updated fields
  Income copyWith({
    String? uuid,
    String? title,
    double? amount,
    DateTime? date,
    IncomeCategory? category,
    String? notes,
    String? source,
    DateTime? createdAt,
  }) {
    final result = Income()
      ..id = id
      ..uuid = uuid ?? this.uuid
      ..title = title ?? this.title
      ..amount = amount ?? this.amount
      ..date = date ?? this.date
      ..categoryIndex = category != null ? category.index : categoryIndex
      ..notes = notes ?? this.notes
      ..source = source ?? this.source
      ..createdAt = createdAt ?? this.createdAt;

    return result;
  }

  /// Factory constructor to create an Income from JSON
  factory Income.fromJson(Map<String, dynamic> json) {
    return Income.create(
      uuid: json['uuid'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: (json['date'] as firestore.Timestamp).toDate(),
      category: IncomeCategory.values[json['categoryIndex'] as int],
      notes: json['notes'] as String?,
      source: json['source'] as String,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as firestore.Timestamp).toDate()
          : null,
    );
  }
}
