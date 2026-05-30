class Exam {
  const Exam({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    required this.price,
    required this.active,
  });

  final String id;
  final String code;
  final String name;
  final String category;
  final double price;
  final bool active;

  factory Exam.fromJson(Map<String, dynamic> json) {
    return Exam(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      category: json['category'] as String? ?? 'AUTRE',
      price: (json['price'] as num).toDouble(),
      active: json['active'] as bool? ?? true,
    );
  }
}
