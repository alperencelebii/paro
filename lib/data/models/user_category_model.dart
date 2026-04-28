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

/// Flutter release build safe icon resolver.
///
/// Dynamic IconData(codePoint, ...) breaks icon tree-shaking in release builds.
/// Therefore all selectable icons are kept in a static const list and stored
/// codePoints are resolved back to one of these const icons.
class CategoryIconResolver {
  static const List<IconData> availableIcons = [
    Icons.restaurant,
    Icons.directions_car,
    Icons.movie,
    Icons.home,
    Icons.shopping_bag,
    Icons.medical_services,
    Icons.school,
    Icons.flight,
    Icons.category,
    Icons.coffee,
    Icons.local_pizza,
    Icons.fastfood,
    Icons.lunch_dining,
    Icons.icecream,
    Icons.local_gas_station,
    Icons.train,
    Icons.directions_bus,
    Icons.directions_bike,
    Icons.pedal_bike,
    Icons.sports_esports,
    Icons.music_note,
    Icons.theaters,
    Icons.tv,
    Icons.devices,
    Icons.phone_iphone,
    Icons.electric_bolt,
    Icons.water_drop,
    Icons.wifi,
    Icons.home_work,
    Icons.shopping_cart,
    Icons.shopping_basket,
    Icons.store,
    Icons.health_and_safety,
    Icons.monitor_heart,
    Icons.healing,
    Icons.book,
    Icons.menu_book,
    Icons.cast_for_education,
    Icons.work,
    Icons.payments,
    Icons.attach_money,
    Icons.savings,
    Icons.card_giftcard,
    Icons.pets,
    Icons.baby_changing_station,
    Icons.cleaning_services,
    Icons.construction,
    Icons.handyman,
    Icons.fitness_center,
    Icons.sports_soccer,
    Icons.spa,
    Icons.airplanemode_active,
    Icons.beach_access,
    Icons.local_taxi,
    Icons.park,
    Icons.kitchen,
    Icons.local_florist,
    Icons.settings,
    Icons.account_balance,
  ];

  static IconData? fromCodePoint(int? codePoint) {
    if (codePoint == null) return null;
    for (final icon in availableIcons) {
      if (icon.codePoint == codePoint) return icon;
    }
    return Icons.category;
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