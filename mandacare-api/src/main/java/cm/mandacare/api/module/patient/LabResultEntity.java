package cm.mandacare.api.module.patient;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "visit_lab_results")
class LabResultEntity {

    @Id
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "patient_id", nullable = false)
    private PatientEntity patient;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "visit_id", nullable = false)
    private VisitEntity visit;

    @Column(name = "result_number", nullable = false, unique = true, length = 60)
    private String resultNumber;

    @Column(name = "dossier_number", length = 60)
    private String dossierNumber;

    @Column(name = "exam_type", nullable = false, length = 180)
    private String examType;

    @Column(columnDefinition = "TEXT")
    private String results;

    @Column(columnDefinition = "TEXT")
    private String observations;

    @Column(name = "sample_date")
    private LocalDate sampleDate;

    @Column(name = "normal_results", nullable = false)
    private boolean normalResults;

    @Column(nullable = false, length = 40)
    private String status;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "validated_at", nullable = false)
    private Instant validatedAt;

    protected LabResultEntity() {
    }

    static LabResultEntity validatedFor(
            VisitEntity visit,
            String resultNumber,
            CreateLabResultRequest request
    ) {
        Instant now = Instant.now();
        LabResultEntity labResult = new LabResultEntity();
        labResult.id = UUID.randomUUID();
        labResult.patient = visit.patient();
        labResult.visit = visit;
        labResult.resultNumber = resultNumber;
        labResult.dossierNumber = normalize(request.dossierNumber());
        labResult.examType = request.examType().trim();
        labResult.results = normalize(request.results());
        labResult.observations = normalize(request.observations());
        labResult.sampleDate = request.sampleDate();
        labResult.normalResults = request.isNormal();
        labResult.status = "VALIDATED";
        labResult.createdAt = now;
        labResult.validatedAt = now;
        return labResult;
    }

    @PrePersist
    void onCreate() {
        Instant now = Instant.now();
        if (createdAt == null) {
            createdAt = now;
        }
        if (validatedAt == null) {
            validatedAt = now;
        }
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

    String resultNumber() {
        return resultNumber;
    }

    String dossierNumber() {
        return dossierNumber;
    }

    String examType() {
        return examType;
    }

    String results() {
        return results;
    }

    String observations() {
        return observations;
    }

    LocalDate sampleDate() {
        return sampleDate;
    }

    boolean normalResults() {
        return normalResults;
    }

    String status() {
        return status;
    }

    Instant createdAt() {
        return createdAt;
    }

    private static String normalize(String value) {
        if (value == null || value.trim().isEmpty()) {
            return null;
        }
        return value.trim();
    }
}
