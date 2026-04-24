// ignore_for_file: prefer_initializing_formals

import 'package:objectbox/objectbox.dart';
import 'package:flutter/material.dart';

/// Type of category for transactions
enum CategoryType {
  expense,
  income,
}

/// Extension for CategoryType serialization
extension CategoryTypeExtension on CategoryType {
  /// Convert to JSON (returns the enum index)
  int toJson() => index;

  /// Create from JSON
  static CategoryType fromJson(int index) =>
      CategoryType.values[index.clamp(0, CategoryType.values.length - 1)];
}

/// User-defined category stored locally (ObjectBox) and in Firestore
@Entity()
class UserCategory {
  @Id()
  int? id;

  /// Stable UUID across devices (used as Firestore document ID)
  @Index()
  String uuid = '';

  /// Display name
  String name = '';

  /// Category type (expense or income)
  int typeIndex = 0;

  /// Optional Material icon codePoint to render with IconData
  int? iconCodePoint;

  /// Optional Material icon font family (defaults to 'MaterialIcons')
  String? iconFontFamily;

  /// ARGB color value
  int colorValue = 0;

  /// Soft-delete flag for safe sync
  bool isDeleted = false;

  @Property(type: PropertyType.date)
  DateTime createdAt = DateTime.now();

  @Property(type: PropertyType.date)
  DateTime updatedAt = DateTime.now();

  /// No-args constructor for ObjectBox
  UserCategory();

  /// Convenience constructor to create a new category
  UserCategory.create({
    int? id,
    required String uuid,
    required String name,
    required CategoryType type,
    int? iconCodePoint,
    String? iconFontFamily,
    required int colorValue,
    bool isDeleted = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    this.id = id;
    this.uuid = uuid;
    this.name = name;
    typeIndex = type.index;
    this.iconCodePoint = iconCodePoint;
    this.iconFontFamily = iconFontFamily;
    this.colorValue = colorValue;
    this.isDeleted = isDeleted;
    this.createdAt = createdAt ?? DateTime.now();
    this.updatedAt = updatedAt ?? DateTime.now();
  }

  CategoryType get type => CategoryType.values[typeIndex];

  IconData? get icon => iconCodePoint != null
      ? IconData(iconCodePoint!, fontFamily: iconFontFamily ?? 'MaterialIcons')
      : null;

  Color get color => Color(colorValue);

  UserCategory copyWith({
    String? uuid,
    String? name,
    CategoryType? type,
    int? iconCodePoint,
    String? iconFontFamily,
    int? colorValue,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final result = UserCategory()
      ..id = id
      ..uuid = uuid ?? this.uuid
      ..name = name ?? this.name
      ..typeIndex = type != null ? type.index : typeIndex
      ..iconCodePoint = iconCodePoint ?? this.iconCodePoint
      ..iconFontFamily = iconFontFamily ?? this.iconFontFamily
      ..colorValue = colorValue ?? this.colorValue
      ..isDeleted = isDeleted ?? this.isDeleted
      ..createdAt = createdAt ?? this.createdAt
      ..updatedAt = updatedAt ?? this.updatedAt;
    return result;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'uuid': uuid,
        'name': name,
        'typeIndex': typeIndex,
        'iconCodePoint': iconCodePoint,
        'iconFontFamily': iconFontFamily,
        'colorValue': colorValue,
        'isDeleted': isDeleted,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// Create from JSON
  factory UserCategory.fromJson(Map<String, dynamic> json) {
    final category = UserCategory()
      ..id = json['id'] as int?
      ..uuid = json['uuid'] as String? ?? ''
      ..name = json['name'] as String? ?? ''
      ..typeIndex = json['typeIndex'] as int? ?? 0
      ..iconCodePoint = json['iconCodePoint'] as int?
      ..iconFontFamily = json['iconFontFamily'] as String?
      ..colorValue = json['colorValue'] as int? ?? 0
      ..isDeleted = json['isDeleted'] as bool? ?? false;
    if (json['createdAt'] != null) {
      category.createdAt = DateTime.parse(json['createdAt'] as String);
    }
    if (json['updatedAt'] != null) {
      category.updatedAt = DateTime.parse(json['updatedAt'] as String);
    }
    return category;
  }
}
