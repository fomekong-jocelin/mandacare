import 'invoice_preview.dart';

class Invoice {
  const Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.totalAmount,
    required this.discount,
    required this.netAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.status,
    required this.createdAt,
    required this.items,
  });

  final String id;
  final String invoiceNumber;
  final double totalAmount;
  final double discount;
  final double netAmount;
  final double paidAmount;
  final double remainingAmount;
  final String status;
  final DateTime createdAt;
  final List<InvoiceLine> items;

  factory Invoice.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    return Invoice(
      id: json['id'] as String,
      invoiceNumber: json['invoiceNumber'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      netAmount: (json['netAmount'] as num).toDouble(),
      paidAmount: (json['paidAmount'] as num).toDouble(),
      remainingAmount: (json['remainingAmount'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(InvoiceLine.fromJson)
          .toList(growable: false),
    );
  }
}
