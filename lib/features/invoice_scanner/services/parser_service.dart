import '../data/models/invoice_model.dart';
import '../data/models/line_item_model.dart';

/// Service for parsing OCR results into structured invoice data
/// Works with Tesseract OCR (plain text) - completely free and open-source
class ParserService {
  static const double defaultConfidence = 0.85;
  static const double lowConfidenceThreshold = 0.70;

  /// Parse OCR text into InvoiceModel
  /// Accepts plain text string from Tesseract
  InvoiceModel parseInvoice(
    String ocrText,
    String invoiceId, {
    String? imagePath,
    String source = 'camera',
  }) {
    // Extract merchant name (usually first line or top text)
    final merchant = _extractMerchant(ocrText);
    final merchantConfidence = merchant.isNotEmpty ? defaultConfidence : 0.0;

    // Extract date
    final date = _extractDate(ocrText);
    final dateConfidence = date != null ? defaultConfidence : 0.0;

    // Extract currency
    final currency = _extractCurrency(ocrText);

    // Extract totals using text-based extraction
    final total = _extractTotalFromText(ocrText);
    final totalConfidence = total != null ? defaultConfidence : 0.0;

    final subtotal = _extractSubtotal(ocrText);
    final subtotalConfidence = subtotal != null ? defaultConfidence : 0.0;

    final tax = _extractTax(ocrText);
    final taxConfidence = tax != null ? defaultConfidence : 0.0;

    // Extract invoice number
    final invoiceNumber = _extractInvoiceNumber(ocrText);
    final invoiceNumberConfidence =
        invoiceNumber != null ? defaultConfidence : 0.0;

    // Extract line items (simplified for text-only parsing)
    final lineItems = _extractLineItemsFromText(ocrText);

    // Build confidence map
    final confidence = <String, double>{
      'merchant': merchantConfidence,
      'date': dateConfidence,
      'total': totalConfidence,
      'subtotal': subtotalConfidence,
      'tax': taxConfidence,
      'invoiceNumber': invoiceNumberConfidence,
    };

    return InvoiceModel(
      id: invoiceId,
      merchant: merchant,
      date: date,
      currency: currency,
      total: total,
      subtotal: subtotal,
      tax: tax,
      lineItems: lineItems,
      confidence: confidence,
      imagePath: imagePath,
      invoiceNumber: invoiceNumber,
      parseTimestamp: DateTime.now(),
      source: source,
      rawOcrText: ocrText, // Store full OCR text for displaying all content
    );
  }

  /// Extract merchant name from text - improved to find shop/food names
  /// Prioritizes business names, restaurant names, and food items
  String _extractMerchant(String text) {
    if (text.isEmpty) return 'Unknown Merchant';
    
    final lines = text.split('\n').where((line) => line.trim().isNotEmpty).toList();
    if (lines.isEmpty) return 'Unknown Merchant';
    
    // Score each line to find the best merchant name candidate
    double bestScore = 0;
    String? bestMerchant;
    
    // Check first 8 lines (merchant name is usually at the top)
    for (int i = 0; i < (lines.length > 8 ? 8 : lines.length); i++) {
      final line = lines[i].trim();
      
      // Skip if too short or too long
      if (line.length < 2 || line.length > 80) continue;
      
      // Skip if it looks like a date, time, address, or receipt header
      if (_isNonMerchantText(line)) continue;
      
      // Calculate score for this line
      double score = _scoreMerchantName(line, i);
      
      if (score > bestScore) {
        bestScore = score;
        bestMerchant = line;
      }
    }
    
    // If we found a good candidate, clean it up
    if (bestMerchant != null && bestScore > 0.3) {
      // Remove common receipt prefixes/suffixes
      bestMerchant = bestMerchant
          .replaceAll(RegExp(r'^(receipt|invoice|bill|order|#)\s*:?\s*', caseSensitive: false), '')
          .replaceAll(RegExp(r'\s*(receipt|invoice|bill|order)$', caseSensitive: false), '')
          .trim();
      
      // Take first few words if too long
      if (bestMerchant.length > 50) {
        final words = bestMerchant.split(RegExp(r'\s+'));
        bestMerchant = words.take(4).join(' ');
      }
      
      return bestMerchant;
    }
    
    // Fallback: return first reasonable line
    for (final line in lines.take(5)) {
      final trimmed = line.trim();
      if (trimmed.length >= 2 && trimmed.length <= 80 && !_isNonMerchantText(trimmed)) {
        return trimmed.length > 50 ? trimmed.split(RegExp(r'\s+')).take(4).join(' ') : trimmed;
      }
    }
    
    return lines.first.trim();
  }
  
  /// Score a line to determine if it's likely a merchant name
  /// Returns score between 0.0 and 1.0
  double _scoreMerchantName(String line, int lineIndex) {
    double score = 0.0;
    final lowerLine = line.toLowerCase();
    
    // Higher score for lines at the top (merchant name is usually first)
    score += (8 - lineIndex) * 0.1;
    
    // Prefer lines with proper capitalization (business names)
    final hasUpperCase = line.contains(RegExp(r'[A-Z]'));
    final hasLowerCase = line.contains(RegExp(r'[a-z]'));
    if (hasUpperCase && hasLowerCase) {
      score += 0.3; // Mixed case suggests proper noun (business name)
    } else if (line == line.toUpperCase() && line.length > 3 && line.length < 30) {
      score += 0.2; // All caps can be business name
    }
    
    // Prefer reasonable length (2-50 chars)
    if (line.length >= 2 && line.length <= 50) {
      score += 0.2;
    } else if (line.length > 50) {
      score -= 0.2; // Too long
    }
    
    // Boost score for common business name patterns
    if (RegExp(r'\b(restaurant|cafe|pizza|burger|shop|store|market|mart|boutique|deli|bakery|bar|grill)\b', caseSensitive: false).hasMatch(lowerLine)) {
      score += 0.3; // Contains business type words
    }
    
    // Boost for food-related words (could be food name)
    if (RegExp(r'\b(pizza|burger|sandwich|pasta|sushi|chicken|beef|salad|soup|coffee|tea|juice|drink|meal|combo|platter)\b', caseSensitive: false).hasMatch(lowerLine)) {
      score += 0.25; // Could be food item name
    }
    
    // Penalize lines with too many numbers
    final numberCount = line.replaceAll(RegExp(r'[^0-9]'), '').length;
    if (numberCount > line.length * 0.3) {
      score -= 0.3; // Too many numbers
    }
    
    // Penalize lines that are mostly special characters
    final specialCharCount = line.replaceAll(RegExp(r'[a-zA-Z0-9\s]'), '').length;
    if (specialCharCount > line.length * 0.3) {
      score -= 0.2;
    }
    
    return score.clamp(0.0, 1.0);
  }

  /// Check if text looks like non-merchant text (date, time, address, etc.)
  bool _isNonMerchantText(String text) {
    final lowerText = text.toLowerCase();
    
    // Date patterns
    if (RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}').hasMatch(text)) return true;
    if (RegExp(r'\b(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\b',
            caseSensitive: false).hasMatch(text)) return true;
    
    // Time patterns
    if (RegExp(r'\d{1,2}:\d{2}\s*(am|pm)?', caseSensitive: false).hasMatch(text)) return true;
    
    // Address patterns
    if (RegExp(r'\b(street|st|avenue|ave|road|rd|drive|dr|lane|ln|boulevard|blvd|address|addr)\b',
            caseSensitive: false).hasMatch(lowerText)) return true;
    
    // Phone number patterns
    if (RegExp(r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b').hasMatch(text)) return true;
    
    // Common receipt header words (not merchant names)
    final nonMerchantWords = [
      'invoice', 'receipt', 'bill', 'date', 'time', 'phone', 'tel', 'fax', 'email',
      'order', 'order#', 'order no', 'order number', 'transaction', 'payment',
      'thank you', 'thanks', 'visit us', 'www.', 'http', 'cashier', 'server',
      'table', 'guest', 'customer', 'subtotal', 'tax', 'total', 'change', 'paid'
    ];
    for (final word in nonMerchantWords) {
      if (lowerText.contains(word)) return true;
    }
    
    // If it's mostly numbers or special characters, likely not merchant name
    final letterCount = text.replaceAll(RegExp(r'[^a-zA-Z]'), '').length;
    if (letterCount < text.length * 0.3) return true;
    
    // Skip lines that are just amounts
    if (RegExp(r'^[₹$€£¥]?\s*[\d,]+\.?\d{0,2}\s*$').hasMatch(text.trim())) return true;
    
    return false;
  }

  /// Extract date from text using various date patterns
  DateTime? _extractDate(String text) {
    final patterns = [
      // Month DD, YYYY
      RegExp(r'\b(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+(\d{1,2}),?\s+(\d{4})\b',
          caseSensitive: false),
      // YYYY-MM-DD
      RegExp(r'\b(\d{4})[-/](\d{1,2})[-/](\d{1,2})\b'),
      // MM/DD/YYYY or DD/MM/YYYY
      RegExp(r'\b(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})\b'),
      // DD Month YYYY
      RegExp(r'\b(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+(\d{4})\b',
          caseSensitive: false),
    ];

    final monthNames = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };

    for (final pattern in patterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        try {
          int? year, month, day;
          
          if (match.groupCount >= 3) {
            final group1 = match.group(1)?.toLowerCase() ?? '';
            final group2 = match.group(2)?.toLowerCase() ?? '';
            final group3 = match.group(3)?.toLowerCase() ?? '';
            
            // Check if first group is a month name
            if (monthNames.containsKey(group1)) {
              month = monthNames[group1];
              day = int.tryParse(group2);
              year = int.tryParse(group3);
            }
            // Check if second group is a month name
            else if (monthNames.containsKey(group2)) {
              day = int.tryParse(group1);
              month = monthNames[group2];
              year = int.tryParse(group3);
            }
            // Numeric date patterns
            else {
              final part1 = int.tryParse(group1);
              final part2 = int.tryParse(group2);
              final part3 = int.tryParse(group3);
              
              if (part1 != null && part2 != null && part3 != null) {
                if (part1 > 31) {
                  // YYYY-MM-DD format
                  year = part1;
                  month = part2;
                  day = part3;
                } else if (part3 > 31 || part3 < 100) {
                  // MM/DD/YYYY format
                  month = part1;
                  day = part2;
                  year = part3;
                  if (year < 100) year += 2000;
                }
              }
            }
          }

          // Validate and return date
          if (year != null && month != null && day != null) {
            if (year >= 2000 && year <= 2100 &&
                month >= 1 && month <= 12 &&
                day >= 1 && day <= 31) {
              try {
                final date = DateTime(year, month, day);
                final now = DateTime.now();
                final yearsDiff = (date.year - now.year).abs();
                if (yearsDiff <= 5) {
                  return date;
                }
              } catch (e) {
                continue;
              }
            }
          }
        } catch (e) {
          continue;
        }
      }
    }

    return null;
  }

  /// Extract currency from text
  String _extractCurrency(String text) {
    // Look for currency symbols or codes
    final currencyPatterns = [
      RegExp(r'₹'), // Indian Rupee
      RegExp(r'\$'), // Dollar
      RegExp(r'€'), // Euro
      RegExp(r'£'), // Pound
      RegExp(r'¥'), // Yen
    ];

    for (final pattern in currencyPatterns) {
      if (pattern.hasMatch(text)) {
        return pattern.stringMatch(text) ?? 'USD';
      }
    }

    // Look for currency codes
    if (RegExp(r'\bUSD\b').hasMatch(text)) return 'USD';
    if (RegExp(r'\bEUR\b').hasMatch(text)) return 'EUR';
    if (RegExp(r'\bGBP\b').hasMatch(text)) return 'GBP';
    if (RegExp(r'\bINR\b').hasMatch(text)) return 'INR';

    return 'USD'; // Default
  }

  /// Extract total from text - improved to find final total amount only
  /// Excludes item amounts and only looks for amounts near "total" keywords
  double? _extractTotalFromText(String text) {
    // First, extract line items to exclude their amounts
    final lineItems = _extractLineItemsFromText(text);
    final itemAmounts = <double>{};
    for (final item in lineItems) {
      itemAmounts.add(item.total);
      itemAmounts.add(item.unitPrice);
    }
    
    // Look for "total" keyword patterns with amounts
    // Priority order: grand total > total > amount due > balance due
    final totalPatterns = [
      // Grand total (highest priority)
      RegExp(r'grand\s+total\s*:?\s*[₹$€£¥]?\s*([\d,]+\.?\d{0,2})', caseSensitive: false),
      // Total (with word boundaries to avoid matching "subtotal")
      RegExp(r'\btotal\b\s*:?\s*[₹$€£¥]?\s*([\d,]+\.?\d{0,2})', caseSensitive: false),
      // Amount due
      RegExp(r'amount\s+due\s*:?\s*[₹$€£¥]?\s*([\d,]+\.?\d{0,2})', caseSensitive: false),
      // Balance due
      RegExp(r'balance\s+due\s*:?\s*[₹$€£¥]?\s*([\d,]+\.?\d{0,2})', caseSensitive: false),
      // Final total
      RegExp(r'final\s+total\s*:?\s*[₹$€£¥]?\s*([\d,]+\.?\d{0,2})', caseSensitive: false),
      // Net total
      RegExp(r'net\s+total\s*:?\s*[₹$€£¥]?\s*([\d,]+\.?\d{0,2})', caseSensitive: false),
    ];

    // Try each pattern and find the best match
    double? bestTotal;
    int bestPatternIndex = -1;
    
    for (int i = 0; i < totalPatterns.length; i++) {
      final pattern = totalPatterns[i];
      final matches = pattern.allMatches(text);
      
      for (final match in matches) {
        final valueStr = match.group(1)?.replaceAll(',', '') ?? '';
        final value = double.tryParse(valueStr);
        
        if (value != null && value > 0) {
          // Skip if this amount matches an item amount (likely not the total)
          if (itemAmounts.any((itemAmount) => (itemAmount - value).abs() < 0.01)) {
            continue;
          }
          
          // Prefer earlier patterns (grand total > total > etc.)
          if (bestTotal == null || i < bestPatternIndex) {
            bestTotal = value;
            bestPatternIndex = i;
          } else if (i == bestPatternIndex && value > bestTotal) {
            // If same pattern, prefer larger amount
            bestTotal = value;
          }
        }
      }
    }
    
    // If we found a total from patterns, return it
    if (bestTotal != null) {
      return bestTotal;
    }
    
    // Fallback: Look for amounts at the bottom of the receipt (where totals usually are)
    // Split text into lines and check last few lines
    final lines = text.split('\n').where((line) => line.trim().isNotEmpty).toList();
    if (lines.length >= 3) {
      // Check last 5 lines for amounts
      final lastLines = lines.sublist(lines.length - 5);
      final amountPattern = RegExp(r'[₹$€£¥]?\s*([\d,]+\.?\d{0,2})');
      
      double? bottomAmount;
      for (final line in lastLines.reversed) {
        final match = amountPattern.firstMatch(line);
        if (match != null) {
          final valueStr = match.group(1)?.replaceAll(',', '') ?? '';
          final value = double.tryParse(valueStr);
          
          if (value != null && value > 0) {
            // Skip if matches item amount
            if (!itemAmounts.any((itemAmount) => (itemAmount - value).abs() < 0.01)) {
              // Prefer larger amounts at the bottom (likely total)
              if (bottomAmount == null || value > bottomAmount) {
                bottomAmount = value;
              }
            }
          }
        }
      }
      
      if (bottomAmount != null) {
        return bottomAmount;
      }
    }
    
    // Last resort: Find largest amount that's not an item amount
    // But only if it's significantly larger than item amounts
    if (itemAmounts.isNotEmpty) {
      final maxItemAmount = itemAmounts.reduce((a, b) => a > b ? a : b);
      final allAmounts = <double>[];
      
      final amountPattern = RegExp(r'[₹$€£¥]?\s*([\d,]+\.?\d{0,2})');
      final matches = amountPattern.allMatches(text);
      
      for (final match in matches) {
        final valueStr = match.group(1)?.replaceAll(',', '') ?? '';
        final value = double.tryParse(valueStr);
        if (value != null && value > 0 && !itemAmounts.contains(value)) {
          allAmounts.add(value);
        }
      }
      
      if (allAmounts.isNotEmpty) {
        allAmounts.sort((a, b) => b.compareTo(a)); // Sort descending
        // Return largest amount that's at least 10% larger than max item amount
        // (likely the total)
        for (final amount in allAmounts) {
          if (amount >= maxItemAmount * 1.1) {
            return amount;
          }
        }
        // If no amount is 10% larger, return the largest non-item amount
        return allAmounts.first;
      }
    }
    
    return null;
  }

  /// Extract subtotal from text
  double? _extractSubtotal(String text) {
    final subtotalPattern = RegExp(
        r'sub\s*total\s*:?\s*[₹$€£¥]?\s*([\d,]+\.?\d{0,2})',
        caseSensitive: false);

    final match = subtotalPattern.firstMatch(text);
    if (match != null) {
      final valueStr = match.group(1)?.replaceAll(',', '') ?? '';
      return double.tryParse(valueStr);
    }

    return null;
  }

  /// Extract tax from text
  double? _extractTax(String text) {
    final taxPatterns = [
      RegExp(r'tax\s*:?\s*[₹$€£¥]?\s*([\d,]+\.?\d{0,2})', caseSensitive: false),
      RegExp(r'vat\s*:?\s*[₹$€£¥]?\s*([\d,]+\.?\d{0,2})', caseSensitive: false),
      RegExp(r'gst\s*:?\s*[₹$€£¥]?\s*([\d,]+\.?\d{0,2})', caseSensitive: false),
    ];

    for (final pattern in taxPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final valueStr = match.group(1)?.replaceAll(',', '') ?? '';
        final value = double.tryParse(valueStr);
        if (value != null && value > 0) {
          return value;
        }
      }
    }

    return null;
  }

  /// Extract invoice number from text
  String? _extractInvoiceNumber(String text) {
    final patterns = [
      RegExp(r'invoice\s*#?\s*:?\s*([A-Z0-9-]+)', caseSensitive: false),
      RegExp(r'inv\s*#?\s*:?\s*([A-Z0-9-]+)', caseSensitive: false),
      RegExp(r'receipt\s*#?\s*:?\s*([A-Z0-9-]+)', caseSensitive: false),
      RegExp(r'bill\s*#?\s*:?\s*([A-Z0-9-]+)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final invoiceNum = match.group(1);
        if (invoiceNum != null && invoiceNum.length >= 3) {
          return invoiceNum;
        }
      }
    }

    return null;
  }

  /// Extract line items from text (simplified)
  List<LineItemModel> _extractLineItemsFromText(String text) {
    final lineItems = <LineItemModel>[];

    // Look for patterns like: "Item name 2 x $10.00 = $20.00"
    final itemPattern = RegExp(
      r'(.+?)\s+(\d+)\s*x?\s*[₹$€£¥]?\s*([\d,]+\.?\d{0,2})\s*=?\s*[₹$€£¥]?\s*([\d,]+\.?\d{0,2})',
      multiLine: true,
    );

    final matches = itemPattern.allMatches(text);
    for (final match in matches) {
      final description = match.group(1)?.trim();
      final quantityStr = match.group(2);
      final priceStr = match.group(3)?.replaceAll(',', '');
      final totalStr = match.group(4)?.replaceAll(',', '');

      if (description != null && quantityStr != null && priceStr != null) {
        final quantity = double.tryParse(quantityStr);
        final price = double.tryParse(priceStr);
        final total = double.tryParse(totalStr ?? priceStr);

        if (quantity != null && price != null && total != null) {
          lineItems.add(LineItemModel(
            description: description,
            quantity: quantity,
            unitPrice: price,
            total: total,
          ));
        }
      }
    }

    return lineItems;
  }
}
