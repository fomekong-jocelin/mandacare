class InvoiceLine {
  const InvoiceLine({
    required this.type,
    required this.label,
    required this.price,
    required this.quantity,
  });

  final String type;
  final String label;
  final double price;
  final int quantity;

  factory InvoiceLine.fromJson(Map<String, dynamic> json) {
    return InvoiceLine(
      type: json['type'] as String,
      label: json['label'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int? ?? 1,
    );
  }
}

class InvoicePreview {
  const InvoicePreview({
    required this.totalAmount,
    required this.discount,
    required this.netAmount,
    required this.items,
  });

  final double totalAmount;
  final double discount;
  final double netAmount;
  final List<InvoiceLine> items;

  factory InvoicePreview.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    return InvoicePreview(
      totalAmount: (json['totalAmount'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      netAmount: (json['netAmount'] as num).toDouble(),
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(InvoiceLine.fromJson)
          .toList(growable: false),
    );
  }
}
