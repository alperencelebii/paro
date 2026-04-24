import 'package:flutter/material.dart';

/// Utility class for managing category colors throughout the app
class CategoryColors {
  /// Get color for expense categories
  static Color getExpenseCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food & dining':
      case 'food':
        return Colors.orange.shade400;
      case 'health':
      case 'healthcare':
      case 'medical':
        return Colors.pink.shade300;
      case 'travel':
      case 'transportation':
        return Colors.amber.shade400;
      case 'shopping':
      case 'retail':
        return Colors.purple.shade400;
      case 'entertainment':
      case 'leisure':
        return Colors.blue.shade400;
      case 'bills':
      case 'utilities':
        return Colors.indigo.shade400;
      case 'education':
      case 'learning':
        return Colors.cyan.shade400;
      case 'housing':
      case 'rent':
        return Colors.brown.shade400;
      case 'insurance':
        return Colors.teal.shade400;
      case 'personal care':
        return Colors.deepPurple.shade400;
      case 'gifts':
      case 'donations':
        return Colors.red.shade400;
      case 'savings':
      case 'investments':
        return Colors.green.shade400;
      default:
        return Colors.blueGrey.shade400;
    }
  }

  /// Get color for income categories
  static Color getIncomeCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'salary':
      case 'wages':
        return Colors.green.shade400;
      case 'investments':
      case 'dividends':
        return Colors.teal.shade400;
      case 'business':
      case 'self-employment':
        return Colors.cyan.shade400;
      case 'rental':
      case 'real estate':
        return Colors.lightGreen.shade400;
      case 'freelance':
      case 'consulting':
        return Colors.lime.shade600;
      case 'pension':
      case 'retirement':
        return Colors.amber.shade400;
      case 'interest':
        return Colors.orange.shade400;
      case 'gifts':
      case 'allowance':
        return Colors.deepOrange.shade400;
      case 'royalties':
        return Colors.purple.shade400;
      case 'other income':
        return Colors.indigo.shade400;
      default:
        return Colors.green.shade200;
    }
  }

  /// Get category color based on type and category name
  static Color getCategoryColor(String category, bool isIncome) {
    return isIncome
        ? getIncomeCategoryColor(category)
        : getExpenseCategoryColor(category);
  }

  /// Get background color for category (lighter shade)
  static Color getCategoryBackgroundColor(String category, bool isIncome) {
    final baseColor = getCategoryColor(category, isIncome);
    // Convert to HSL for better control over lightness
    final HSLColor hslColor = HSLColor.fromColor(baseColor);
    // Return a lighter version with 95% lightness
    return hslColor.withLightness(0.95).toColor();
  }

  /// Get a gradient for category
  static LinearGradient getCategoryGradient(String category, bool isIncome) {
    final baseColor = getCategoryColor(category, isIncome);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        baseColor.withValues(alpha: 0.7),
        baseColor,
      ],
    );
  }
}
