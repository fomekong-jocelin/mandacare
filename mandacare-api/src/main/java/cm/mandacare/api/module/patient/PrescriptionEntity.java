package cm.mandacare.api.module.patient;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
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
@Table(name = "prescriptions")
class PrescriptionEntity {

    @Id
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "patient_id", nullable = false)
    private PatientEntity patient;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "consultation_id", nullable = false)
    private ConsultationEntity consultation;

    @Column(name = "prescription_number", nullable = false, unique = true, length = 60)
    private String prescriptionNumber;

    @Column(name = "prescripteur_id")
    private UUID prescripteurId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 40)
    private PrescriptionStatus status;

    @Column(name = "pdf_url", columnDefinition = "TEXT")
    private String pdfUrl;

    @Column(name = "qr_code", columnDefinition = "TEXT")
    private String qrCode;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "validated_at")
    private Instant validatedAt;

    @OneToMany(mappedBy = "prescription", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<PrescriptionItemEntity> items = new ArrayList<>();

    protected PrescriptionEntity() {
    }

    static PrescriptionEntity create(
            PatientEntity patient,
            ConsultationEntity consultation,
            String prescriptionNumber,
            UUID prescripteurId,
            PrescriptionStatus status
    ) {
        PrescriptionEntity prescription = new PrescriptionEntity();
        prescription.id = UUID.randomUUID();
        prescription.patient = patient;
        prescription.consultation = consultation;
        prescription.prescriptionNumber = prescriptionNumber;
        prescription.prescripteurId = prescripteurId;
        prescription.status = status;
        prescription.createdAt = Instant.now();
        if (status == PrescriptionStatus.VALIDATED) {
            prescription.validatedAt = Instant.now();
        }
        return prescription;
    }

    void updateStatus(PrescriptionStatus status) {
        this.status = status;
        if (status == PrescriptionStatus.VALIDATED && this.validatedAt == null) {
            this.validatedAt = Instant.now();
        }
    }

    void setPdfUrl(String pdfUrl) {
        this.pdfUrl = pdfUrl;
    }

    void setQrCode(String qrCode) {
        this.qrCode = qrCode;
    }

    void addItem(PrescriptionItemEntity item) {
        items.add(item);
        item.setPrescription(this);
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

    String prescriptionNumber() {
        return prescriptionNumber;
    }

    UUID prescripteurId() {
        return prescripteurId;
    }

    PrescriptionStatus status() {
        return status;
    }

    String pdfUrl() {
        return pdfUrl;
    }

    String qrCode() {
        return qrCode;
    }

    Instant createdAt() {
        return createdAt;
    }

    Instant validatedAt() {
        return validatedAt;
    }

    List<PrescriptionItemEntity> items() {
        return items;
    }
}
