class PharmacyItem {
  const PharmacyItem({
    required this.id,
    required this.code,
    required this.label,
    this.dosage,
    required this.price,
    required this.stockQuantity,
    required this.alertThreshold,
    required this.critical,
  });

  final String id;
  final String code;
  final String label;
  final String? dosage;
  final double price;
  final int stockQuantity;
  final int alertThreshold;
  final bool critical;

  factory PharmacyItem.fromJson(Map<String, dynamic> json) {
    return PharmacyItem(
      id: json['id'] as String,
      code: json['code'] as String,
      label: json['label'] as String,
      dosage: json['dosage'] as String?,
      price: (json['price'] as num).toDouble(),
      stockQuantity: json['stockQuantity'] as int,
      alertThreshold: json['alertThreshold'] as int,
      critical: json['critical'] as bool,
    );
  }
}
