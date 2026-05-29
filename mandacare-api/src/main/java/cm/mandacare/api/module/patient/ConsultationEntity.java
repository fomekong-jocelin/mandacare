package cm.mandacare.api.module.patient;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "consultations")
class ConsultationEntity {

    @Id
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "patient_id", nullable = false)
    private PatientEntity patient;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "visit_id", nullable = false)
    private VisitEntity visit;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String reason;

    @Column(columnDefinition = "TEXT")
    private String symptoms;

    @Column(name = "clinical_exam", columnDefinition = "TEXT")
    private String clinicalExam;

    @Column(name = "final_diagnosis", columnDefinition = "TEXT")
    private String finalDiagnosis;

    @Column(columnDefinition = "TEXT")
    private String advice;

    @Column(name = "confidential_notes", columnDefinition = "TEXT")
    private String confidentialNotes;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 40)
    private ConsultationStatus status;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 40)
    private ConsultationDecision decision;

    @Column(name = "validated_at")
    private Instant validatedAt;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected ConsultationEntity() {
    }

    static ConsultationEntity create(VisitEntity visit, CreateConsultationRequest request) {
        ConsultationEntity consultation = new ConsultationEntity();
        consultation.id = UUID.randomUUID();
        consultation.patient = visit.patient();
        consultation.visit = visit;
        consultation.reason = visit.reason();
        consultation.symptoms = normalize(request.symptoms());
        consultation.clinicalExam = normalize(request.clinicalExam());
        consultation.finalDiagnosis = normalize(request.diagnosis());
        consultation.advice = normalize(request.advice());
        consultation.confidentialNotes = normalize(request.confidentialNotes());
        consultation.status = request.getStatusOrDefault();
        consultation.decision = request.decision();
        if (consultation.status == ConsultationStatus.VALIDATED) {
            consultation.validatedAt = Instant.now();
        }
        return consultation;
    }

    void update(CreateConsultationRequest request, ConsultationStatus nextStatus) {
        if (this.status == ConsultationStatus.VALIDATED || this.status == ConsultationStatus.CORRECTED) {
            throw new IllegalStateException("Impossible de modifier une consultation déjà validée.");
        }
        this.symptoms = normalize(request.symptoms());
        this.clinicalExam = normalize(request.clinicalExam());
        this.finalDiagnosis = normalize(request.diagnosis());
        this.advice = normalize(request.advice());
        this.confidentialNotes = normalize(request.confidentialNotes());
        this.status = nextStatus;
        this.decision = request.decision();
        if (nextStatus == ConsultationStatus.VALIDATED) {
            this.validatedAt = Instant.now();
        }
    }

    void markCorrected(CreateConsultationRequest request) {
        this.symptoms = normalize(request.symptoms());
        this.clinicalExam = normalize(request.clinicalExam());
        this.finalDiagnosis = normalize(request.diagnosis());
        this.advice = normalize(request.advice());
        this.confidentialNotes = normalize(request.confidentialNotes());
        this.decision = request.decision();
        this.status = ConsultationStatus.CORRECTED;
        this.updatedAt = Instant.now();
    }

    private static String normalize(String value) {
        if (value == null || value.trim().isEmpty()) {
            return null;
        }
        return value.trim();
    }

    @PrePersist
    void onCreate() {
        Instant now = Instant.now();
        createdAt = now;
        updatedAt = now;
    }

    @PreUpdate
    void onUpdate() {
        updatedAt = Instant.now();
    }

    UUID id() {
        return id;
    }

    PatientEntity patient() {
        return patient;
    }

    VisitEntity visit() {
        return visit;
    }

    UUID patientId() {
        return patient.id();
    }

    UUID visitId() {
        return visit.id();
    }

    String reason() {
        return reason;
    }

    String symptoms() {
        return symptoms;
    }

    String clinicalExam() {
        return clinicalExam;
    }

    String finalDiagnosis() {
        return finalDiagnosis;
    }

    String advice() {
        return advice;
    }

    String confidentialNotes() {
        return confidentialNotes;
    }

    ConsultationStatus status() {
        return status;
    }

    ConsultationDecision decision() {
        return decision;
    }

    Instant validatedAt() {
        return validatedAt;
    }

    Instant createdAt() {
        return createdAt;
    }
}
