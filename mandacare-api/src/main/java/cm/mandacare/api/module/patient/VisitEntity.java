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
@Table(name = "visits")
class VisitEntity {

    @Id
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "patient_id", nullable = false)
    private PatientEntity patient;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String reason;

    @Enumerated(EnumType.STRING)
    @Column(name = "target_service", nullable = false, length = 40)
    private TargetService targetService;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 40)
    private VisitStatus status;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private VisitPriority priority;

    @Column(name = "arrival_at", nullable = false)
    private Instant arrivalAt;

    @Column(name = "closed_at")
    private Instant closedAt;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected VisitEntity() {
    }

    static VisitEntity openFor(PatientEntity patient, CreatePatientRequest request) {
        return open(
                patient,
                request.arrivalReason(),
                request.targetService(),
                request.priority()
        );
    }

    static VisitEntity openFor(PatientEntity patient, CreateVisitRequest request) {
        return open(patient, request.reason(), request.targetService(), request.priority());
    }

    private static VisitEntity open(
            PatientEntity patient,
            String reason,
            TargetService targetService,
            VisitPriority priority
    ) {
        VisitEntity visit = new VisitEntity();
        visit.id = UUID.randomUUID();
        visit.patient = patient;
        visit.reason = reason.trim();
        visit.targetService = targetService == null
                ? TargetService.CONSULTATION
                : targetService;
        visit.status = VisitStatus.WAITING;
        visit.priority = priority;
        visit.arrivalAt = Instant.now();
        return visit;
    }

    void changeStatus(VisitStatus nextStatus) {
        status = nextStatus;
        closedAt = nextStatus == VisitStatus.RELEASED ? Instant.now() : null;
    }

    void markReadyForConsultation() {
        if (status == VisitStatus.WAITING) {
            changeStatus(VisitStatus.IN_CONSULTATION);
        }
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

    UUID patientId() {
        return patient.id();
    }

    PatientEntity patient() {
        return patient;
    }

    String reason() {
        return reason;
    }

    TargetService targetService() {
        return targetService;
    }

    VisitStatus status() {
        return status;
    }

    VisitPriority priority() {
        return priority;
    }

    Instant arrivalAt() {
        return arrivalAt;
    }

    Instant closedAt() {
        return closedAt;
    }
}
