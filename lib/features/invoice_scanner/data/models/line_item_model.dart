/// Model representing a line item from an invoice/receipt
class LineItemModel {
  final String description;
  final double quantity;
  final double unitPrice;
  final double total;

  const LineItemModel({
    required this.description,
    this.quantity = 1.0,
    required this.unitPrice,
    required this.total,
  });

  LineItemModel copyWith({
    String? description,
    double? quantity,
    double? unitPrice,
    double? total,
  }) {
    return LineItemModel(
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      total: total ?? this.total,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'total': total,
    };
  }

  factory LineItemModel.fromMap(Map<String, dynamic> map) {
    return LineItemModel(
      description: map['description'] as String,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
      unitPrice: (map['unitPrice'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
    );
  }
}

