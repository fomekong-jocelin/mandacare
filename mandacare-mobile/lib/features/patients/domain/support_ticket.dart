class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.subject,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.userId,
  });

  final String id;
  final String subject;
  final String description;
  final String category;
  final String priority;
  final String status;
  final DateTime createdAt;
  final String userId;

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'] as String,
      subject: json['subject'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      priority: json['priority'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      userId: json['userId'] as String,
    );
  }
}
