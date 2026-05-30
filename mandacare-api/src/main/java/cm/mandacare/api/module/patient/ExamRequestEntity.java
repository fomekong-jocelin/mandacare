package cm.mandacare.api.module.patient;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "exam_requests")
class ExamRequestEntity {

    @Id
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "patient_id", nullable = false)
    private PatientEntity patient;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "consultation_id")
    private ConsultationEntity consultation;

    @Column(name = "request_number", nullable = false, unique = true, length = 60)
    private String requestNumber;

    @Column(nullable = false, length = 40)
    private String status;

    @Column(nullable = false, length = 30)
    private String priority;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @OneToMany(mappedBy = "examRequest", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<ExamRequestLineEntity> lines = new ArrayList<>();

    protected ExamRequestEntity() {
    }

    static ExamRequestEntity create(
            PatientEntity patient,
            ConsultationEntity consultation,
            String requestNumber,
            String priority
    ) {
        ExamRequestEntity request = new ExamRequestEntity();
        request.id = UUID.randomUUID();
        request.patient = patient;
        request.consultation = consultation;
        request.requestNumber = requestNumber;
        request.status = "PRESCRIBED";
        request.priority = priority;
        request.createdAt = Instant.now();
        return request;
    }

    void addLine(ExamRequestLineEntity line) {
        lines.add(line);
        line.setExamRequest(this);
    }

    void updateStatus(String nextStatus) {
        this.status = nextStatus;
    }

    UUID id() {
        return id;
    }

    PatientEntity patient() {
        return patient;
    }

    ConsultationEntity consultation() {
        return consultation;
    }

    String requestNumber() {
        return requestNumber;
    }

    String status() {
        return status;
    }

    String priority() {
        return priority;
    }

    Instant createdAt() {
        return createdAt;
    }

    List<ExamRequestLineEntity> lines() {
        return lines;
    }
}
