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
import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
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

    @OneToMany(mappedBy = "invoice", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<InvoiceItemEntity> items = new ArrayList<>();

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

    static InvoiceEntity createDetailed(
            VisitEntity visit,
            String invoiceNumber,
            BigDecimal totalAmount,
            BigDecimal discount,
            BigDecimal paidAmount,
            String status,
            List<InvoiceItemEntity> lines
    ) {
        InvoiceEntity invoice = new InvoiceEntity();
        invoice.id = UUID.randomUUID();
        invoice.patient = visit.patient();
        invoice.visit = visit;
        invoice.invoiceNumber = invoiceNumber;
        invoice.totalAmount = totalAmount;
        invoice.discount = discount;
        invoice.netAmount = totalAmount.subtract(discount);
        invoice.paidAmount = paidAmount;
        invoice.remainingAmount = invoice.netAmount.subtract(paidAmount);
        invoice.status = status;
        invoice.createdAt = Instant.now();
        for (InvoiceItemEntity line : lines) {
            invoice.addItem(line);
        }
        return invoice;
    }

    void addItem(InvoiceItemEntity item) {
        items.add(item);
        item.setInvoice(this);
    }

    UUID id() {
        return id;
    }

    PatientEntity patient() {
        return patient;
    }

    Instant createdAt() {
        return createdAt;
    }

    List<InvoiceItemEntity> items() {
        return items;
    }

    BigDecimal totalAmount() {
        return totalAmount;
    }

    BigDecimal discount() {
        return discount;
    }

    BigDecimal netAmount() {
        return netAmount;
    }

    BigDecimal paidAmount() {
        return paidAmount;
    }

    BigDecimal remainingAmount() {
        return remainingAmount;
    }

    String status() {
        return status;
    }

    String invoiceNumber() {
        return invoiceNumber;
    }
}
