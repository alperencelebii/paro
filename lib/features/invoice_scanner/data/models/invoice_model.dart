import 'line_item_model.dart';

/// Model representing parsed invoice/receipt data
class InvoiceModel {
  final String id;
  final String merchant;
  final DateTime? date;
  final String currency;
  final double? total;
  final double? subtotal;
  final double? tax;
  final List<LineItemModel> lineItems;
  final Map<String, double> confidence; // field -> confidence score (0.0-1.0)
  final String? imagePath; // local cache path
  final String? invoiceNumber;
  final DateTime parseTimestamp;
  final String source; // 'camera' or 'gallery'
  final String? rawOcrText; // Full OCR text for displaying all content

   InvoiceModel({
    required this.id,
    required this.merchant,
    this.date,
    this.currency = 'USD',
    this.total,
    this.subtotal,
    this.tax,
    this.lineItems = const [],
    this.confidence = const {},
    this.imagePath,
    this.invoiceNumber,
    DateTime? parseTimestamp,
    this.source = 'camera',
    this.rawOcrText,
  }) : parseTimestamp = parseTimestamp ?? DateTime(1970);

  InvoiceModel copyWith({
    String? id,
    String? merchant,
    DateTime? date,
    String? currency,
    double? total,
    double? subtotal,
    double? tax,
    List<LineItemModel>? lineItems,
    Map<String, double>? confidence,
    String? imagePath,
    String? invoiceNumber,
    DateTime? parseTimestamp,
    String? source,
    String? rawOcrText,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      merchant: merchant ?? this.merchant,
      date: date ?? this.date,
      currency: currency ?? this.currency,
      total: total ?? this.total,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      lineItems: lineItems ?? this.lineItems,
      confidence: confidence ?? this.confidence,
      imagePath: imagePath ?? this.imagePath,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      parseTimestamp: parseTimestamp ?? this.parseTimestamp,
      source: source ?? this.source,
      rawOcrText: rawOcrText ?? this.rawOcrText,
    );
  }

  /// Get confidence for a specific field
  double getFieldConfidence(String field) {
    return confidence[field] ?? 0.0;
  }

  /// Check if a field has low confidence (below threshold)
  bool isLowConfidence(String field, {double threshold = 0.70}) {
    return getFieldConfidence(field) < threshold;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'merchant': merchant,
      'date': date?.toIso8601String(),
      'currency': currency,
      'total': total,
      'subtotal': subtotal,
      'tax': tax,
      'lineItems': lineItems.map((item) => item.toMap()).toList(),
      'confidence': confidence,
      'imagePath': imagePath,
      'invoiceNumber': invoiceNumber,
      'parseTimestamp': parseTimestamp.toIso8601String(),
      'source': source,
      'rawOcrText': rawOcrText,
    };
  }

  factory InvoiceModel.fromMap(Map<String, dynamic> map) {
    return InvoiceModel(
      id: map['id'] as String,
      merchant: map['merchant'] as String,
      date: map['date'] != null
          ? DateTime.parse(map['date'] as String)
          : null,
      currency: map['currency'] as String? ?? 'USD',
      total: (map['total'] as num?)?.toDouble(),
      subtotal: (map['subtotal'] as num?)?.toDouble(),
      tax: (map['tax'] as num?)?.toDouble(),
      lineItems: (map['lineItems'] as List<dynamic>?)
              ?.map((item) => LineItemModel.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      confidence: (map['confidence'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(key, (value as num).toDouble())) ??
          {},
      imagePath: map['imagePath'] as String?,
      invoiceNumber: map['invoiceNumber'] as String?,
      parseTimestamp: map['parseTimestamp'] != null
          ? DateTime.parse(map['parseTimestamp'] as String)
          : DateTime.now(),
      source: map['source'] as String? ?? 'camera',
      rawOcrText: map['rawOcrText'] as String?,
    );
  }
}

