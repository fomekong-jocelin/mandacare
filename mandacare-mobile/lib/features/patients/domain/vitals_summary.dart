class VitalsSummary {
  const VitalsSummary({
    this.id,
    required this.visitId,
    this.patientId,
    this.temperature,
    this.systolicPressure,
    this.diastolicPressure,
    this.pulse,
    this.respiratoryRate,
    this.oxygenSaturation,
    this.weight,
    this.height,
    this.bmi,
    this.bloodGlucose,
    this.createdAt,
  });

  final String? id;
  final String visitId;
  final String? patientId;
  final double? temperature;
  final int? systolicPressure;
  final int? diastolicPressure;
  final int? pulse;
  final int? respiratoryRate;
  final int? oxygenSaturation;
  final double? weight;
  final double? height;
  final double? bmi;
  final double? bloodGlucose;
  final DateTime? createdAt;
}
