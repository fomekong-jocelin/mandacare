package cm.mandacare.api.module.patient;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "invoices")
class InvoiceEntity {

    @Id
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "patient_id", nullable = false)
    private PatientEntity patient;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "visit_id")
    private VisitEntity visit;

    @Column(name = "invoice_number", nullable = false, unique = true, length = 60)
    private String invoiceNumber;

    @Column(name = "total_amount", nullable = false, precision = 12, scale = 2)
    private BigDecimal totalAmount;

    @Column(nullable = false, precision = 12, scale = 2)
    private BigDecimal discount;

    @Column(name = "net_amount", nullable = false, precision = 12, scale = 2)
    private BigDecimal netAmount;

    @Column(name = "paid_amount", nullable = false, precision = 12, scale = 2)
    private BigDecimal paidAmount;

    @Column(name = "remaining_amount", nullable = false, precision = 12, scale = 2)
    private BigDecimal remainingAmount;

    @Column(nullable = false, length = 40)
    private String status;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    protected InvoiceEntity() {
    }

    static InvoiceEntity paidFor(VisitEntity visit, String invoiceNumber, BigDecimal amount) {
        InvoiceEntity invoice = new InvoiceEntity();
        invoice.id = UUID.randomUUID();
        invoice.patient = visit.patient();
        invoice.visit = visit;
        invoice.invoiceNumber = invoiceNumber;
        invoice.totalAmount = amount;
        invoice.discount = BigDecimal.ZERO;
        invoice.netAmount = amount;
        invoice.paidAmount = amount;
        invoice.remainingAmount = BigDecimal.ZERO;
        invoice.status = "PAID";
        invoice.createdAt = Instant.now();
        return invoice;
    }

    UUID id() {
        return id;
    }
}
