package cm.mandacare.api.module.patient;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "vitals")
class VitalsEntity {

    @Id
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "patient_id", nullable = false)
    private PatientEntity patient;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "visit_id", nullable = false)
    private VisitEntity visit;

    private BigDecimal temperature;

    @Column(name = "systolic_pressure")
    private Integer systolicPressure;

    @Column(name = "diastolic_pressure")
    private Integer diastolicPressure;

    private Integer pulse;

    @Column(name = "respiratory_rate")
    private Integer respiratoryRate;

    @Column(name = "oxygen_saturation")
    private Integer oxygenSaturation;

    private BigDecimal weight;
    private BigDecimal height;
    private BigDecimal bmi;

    @Column(name = "blood_glucose")
    private BigDecimal bloodGlucose;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    protected VitalsEntity() {
    }

    static VitalsEntity create(VisitEntity visit, CreateVitalsRequest request) {
        VitalsEntity vitals = new VitalsEntity();
        vitals.id = UUID.randomUUID();
        vitals.patient = visit.patient();
        vitals.visit = visit;
        vitals.temperature = request.temperature();
        vitals.systolicPressure = request.systolicPressure();
        vitals.diastolicPressure = request.diastolicPressure();
        vitals.pulse = request.pulse();
        vitals.respiratoryRate = request.respiratoryRate();
        vitals.oxygenSaturation = request.oxygenSaturation();
        vitals.weight = request.weight();
        vitals.height = request.height();
        vitals.bmi = calculateBmi(request.weight(), request.height());
        vitals.bloodGlucose = request.bloodGlucose();
        return vitals;
    }

    @PrePersist
    void onCreate() {
        createdAt = Instant.now();
    }

    UUID id() {
        return id;
    }

    UUID visitId() {
        return visit.id();
    }

    UUID patientId() {
        return patient.id();
    }

    BigDecimal temperature() {
        return temperature;
    }

    Integer systolicPressure() {
        return systolicPressure;
    }

    Integer diastolicPressure() {
        return diastolicPressure;
    }

    Integer pulse() {
        return pulse;
    }

    Integer respiratoryRate() {
        return respiratoryRate;
    }

    Integer oxygenSaturation() {
        return oxygenSaturation;
    }

    BigDecimal weight() {
        return weight;
    }

    BigDecimal height() {
        return height;
    }

    BigDecimal bmi() {
        return bmi;
    }

    BigDecimal bloodGlucose() {
        return bloodGlucose;
    }

    Instant createdAt() {
        return createdAt;
    }

    private static BigDecimal calculateBmi(BigDecimal weight, BigDecimal height) {
        if (weight == null || height == null || height.signum() <= 0) {
            return null;
        }
        BigDecimal heightInMeters = height.divide(BigDecimal.valueOf(100), 4, RoundingMode.HALF_UP);
        BigDecimal squaredHeight = heightInMeters.multiply(heightInMeters);
        return weight.divide(squaredHeight, 2, RoundingMode.HALF_UP);
    }
}
