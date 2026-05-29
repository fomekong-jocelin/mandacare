enum PrescriptionStatus {
  draft,
  validated,
  sent,
  printed;

  String get apiValue => name.toUpperCase();

  static PrescriptionStatus fromApiValue(String value) {
    return PrescriptionStatus.values.firstWhere(
      (e) => e.apiValue == value,
      orElse: () => PrescriptionStatus.draft,
    );
  }
}

class Prescription {
  const Prescription({
    required this.id,
    required this.patientId,
    required this.consultationId,
    required this.prescriptionNumber,
    this.prescripteurId,
    required this.status,
    this.pdfUrl,
    this.qrCode,
    required this.createdAt,
    this.validatedAt,
    required this.items,
  });

  final String id;
  final String patientId;
  final String consultationId;
  final String prescriptionNumber;
  final String? prescripteurId;
  final PrescriptionStatus status;
  final String? pdfUrl;
  final String? qrCode;
  final DateTime createdAt;
  final DateTime? validatedAt;
  final List<PrescriptionItem> items;

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      consultationId: json['consultationId'] as String,
      prescriptionNumber: json['prescriptionNumber'] as String,
      prescripteurId: json['prescripteurId'] as String?,
      status: PrescriptionStatus.fromApiValue(json['status'] as String),
      pdfUrl: json['pdfUrl'] as String?,
      qrCode: json['qrCode'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      validatedAt: json['validatedAt'] != null
          ? DateTime.parse(json['validatedAt'] as String)
          : null,
      items: (json['items'] as List<dynamic>)
          .map(
            (item) => PrescriptionItem.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class PrescriptionItem {
  PrescriptionItem({
    required this.id,
    required this.drugName,
    this.form,
    this.dosage,
    this.frequency,
    this.duration,
    this.quantity,
    this.instructions,
  });

  final String id;
  String drugName;
  String? form;
  String? dosage;
  String? frequency;
  String? duration;
  int? quantity;
  String? instructions;

  factory PrescriptionItem.fromJson(Map<String, dynamic> json) {
    return PrescriptionItem(
      id: json['id'] as String,
      drugName: json['drugName'] as String,
      form: json['form'] as String?,
      dosage: json['dosage'] as String?,
      frequency: json['frequency'] as String?,
      duration: json['duration'] as String?,
      quantity: json['quantity'] as int?,
      instructions: json['instructions'] as String?,
    );
  }
}

class CreatePrescriptionPayload {
  const CreatePrescriptionPayload({required this.status, required this.items});

  final PrescriptionStatus status;
  final List<CreatePrescriptionItemPayload> items;

  Map<String, dynamic> toJson() {
    return {
      'status': status.apiValue,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class CreatePrescriptionItemPayload {
  const CreatePrescriptionItemPayload({
    required this.drugName,
    this.form,
    this.dosage,
    this.frequency,
    this.duration,
    this.quantity,
    this.instructions,
  });

  final String drugName;
  final String? form;
  final String? dosage;
  final String? frequency;
  final String? duration;
  final int? quantity;
  final String? instructions;

  Map<String, dynamic> toJson() {
    return {
      'drugName': drugName.trim(),
      'form': form?.trim().isEmpty == true ? null : form?.trim(),
      'dosage': dosage?.trim().isEmpty == true ? null : dosage?.trim(),
      'frequency': frequency?.trim().isEmpty == true ? null : frequency?.trim(),
      'duration': duration?.trim().isEmpty == true ? null : duration?.trim(),
      'quantity': quantity,
      'instructions': instructions?.trim().isEmpty == true
          ? null
          : instructions?.trim(),
    }..removeWhere((_, value) => value == null);
  }
}
