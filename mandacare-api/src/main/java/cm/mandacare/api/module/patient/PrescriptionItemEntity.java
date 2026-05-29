package cm.mandacare.api.module.patient;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.util.UUID;

@Entity
@Table(name = "prescription_items")
class PrescriptionItemEntity {

    @Id
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "prescription_id", nullable = false)
    private PrescriptionEntity prescription;

    @Column(name = "drug_name", nullable = false)
    private String drugName;

    @Column(length = 120)
    private String form;

    @Column(length = 120)
    private String dosage;

    @Column(length = 120)
    private String frequency;

    @Column(length = 120)
    private String duration;

    private Integer quantity;

    @Column(columnDefinition = "TEXT")
    private String instructions;

    protected PrescriptionItemEntity() {
    }

    static PrescriptionItemEntity create(
            String drugName,
            String form,
            String dosage,
            String frequency,
            String duration,
            Integer quantity,
            String instructions
    ) {
        PrescriptionItemEntity item = new PrescriptionItemEntity();
        item.id = UUID.randomUUID();
        item.drugName = drugName.trim();
        item.form = normalize(form);
        item.dosage = normalize(dosage);
        item.frequency = normalize(frequency);
        item.duration = normalize(duration);
        item.quantity = quantity;
        item.instructions = normalize(instructions);
        return item;
    }

    private static String normalize(String value) {
        if (value == null || value.trim().isEmpty()) {
            return null;
        }
        return value.trim();
    }

    void setPrescription(PrescriptionEntity prescription) {
        this.prescription = prescription;
    }

    UUID id() {
        return id;
    }

    String drugName() {
        return drugName;
    }

    String form() {
        return form;
    }

    String dosage() {
        return dosage;
    }

    String frequency() {
        return frequency;
    }

    String duration() {
        return duration;
    }

    Integer quantity() {
        return quantity;
    }

    String instructions() {
        return instructions;
    }
}
