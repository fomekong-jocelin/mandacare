package cm.mandacare.api.module.patient;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.util.UUID;

@Entity
@Table(name = "invoice_items")
class InvoiceItemEntity {

    @Id
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "invoice_id", nullable = false)
    private InvoiceEntity invoice;

    @Column(nullable = false, length = 40)
    private String type; // EXAM or BENEFIT

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "exam_id")
    private ExamEntity exam;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "benefit_id")
    private BenefitEntity benefit;

    @Column(nullable = false, length = 180)
    private String label;

    @Column(nullable = false, precision = 12, scale = 2)
    private BigDecimal price;

    @Column(nullable = false)
    private int quantity;

    protected InvoiceItemEntity() {
    }

    static InvoiceItemEntity forExam(ExamEntity exam, BigDecimal price, int quantity) {
        InvoiceItemEntity item = new InvoiceItemEntity();
        item.id = UUID.randomUUID();
        item.type = "EXAM";
        item.exam = exam;
        item.label = exam.name();
        item.price = price;
        item.quantity = quantity;
        return item;
    }

    static InvoiceItemEntity forBenefit(BenefitEntity benefit, BigDecimal price, int quantity) {
        InvoiceItemEntity item = new InvoiceItemEntity();
        item.id = UUID.randomUUID();
        item.type = "BENEFIT";
        item.benefit = benefit;
        item.label = benefit.name();
        item.price = price;
        item.quantity = quantity;
        return item;
    }

    void setInvoice(InvoiceEntity invoice) {
        this.invoice = invoice;
    }

    UUID id() {
        return id;
    }

    InvoiceEntity invoice() {
        return invoice;
    }

    String type() {
        return type;
    }

    ExamEntity exam() {
        return exam;
    }

    BenefitEntity benefit() {
        return benefit;
    }

    String label() {
        return label;
    }

    BigDecimal price() {
        return price;
    }

    int quantity() {
        return quantity;
    }
}
