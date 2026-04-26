// ignore_for_file: prefer_initializing_formals

import 'package:objectbox/objectbox.dart';
import 'package:flutter/material.dart';

enum CategoryType {
  expense,
  income,
}

extension CategoryTypeExtension on CategoryType {
  int toJson() => index;

  static CategoryType fromJson(int index) =>
      CategoryType.values[index.clamp(0, CategoryType.values.length - 1)];
}

/// Flutter release build için güvenli icon resolver
class CategoryIconResolver {
  static const Map<int, IconData> icons = {
    0xe532: Icons.restaurant,
    0xe59c: Icons.directions_car,
    0xe8cc: Icons.shopping_cart,
    0xe88a: Icons.home,
    0xe227: Icons.attach_money,
    0xe8f6: Icons.local_hospital,
    0xe53f: Icons.local_gas_station,
    0xe80c: Icons.school,
    0xe3f3: Icons.movie,
    0xe8b8: Icons.settings,
    0xe574: Icons.flight,
    0xe57d: Icons.train,
    0xe530: Icons.directions_bus,
    0xe541: Icons.local_taxi,
    0xe8e5: Icons.work,
    0xe263: Icons.savings,
    0xe850: Icons.account_balance,
    0xe2c7: Icons.category,
  };

  static IconData? fromCodePoint(int? codePoint) {
    if (codePoint == null) return null;
    return icons[codePoint] ?? Icons.category;
  }
}

@Entity()
class UserCategory {
  @Id()
  int? id;

  @Index()
  String uuid = '';

  String name = '';

  int typeIndex = 0;

  /// Optional Material icon codePoint.
  /// Not directly converted with IconData(...) because release build fails.
  int? iconCodePoint;

  /// Kept for backward compatibility, but no longer used for IconData creation.
  String? iconFontFamily;

  int colorValue = 0;

  bool isDeleted = false;

  @Property(type: PropertyType.date)
  DateTime createdAt = DateTime.now();

  @Property(type: PropertyType.date)
  DateTime updatedAt = DateTime.now();

  UserCategory();

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

  IconData? get icon => CategoryIconResolver.fromCodePoint(iconCodePoint);

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