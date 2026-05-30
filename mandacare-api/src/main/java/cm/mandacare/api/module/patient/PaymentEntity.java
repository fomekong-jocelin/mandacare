package cm.mandacare.api.module.patient;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "payments")
class PaymentEntity {

    @Id
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "invoice_id", nullable = false)
    private InvoiceEntity invoice;

    @Column(nullable = false, precision = 12, scale = 2)
    private BigDecimal amount;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 40)
    private PaymentMode mode;

    @Column(length = 120)
    private String reference;

    @Column(nullable = false, length = 40)
    private String status;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    protected PaymentEntity() {
    }

    static PaymentEntity validatedFor(InvoiceEntity invoice, CashDeskPaymentRequest request) {
        PaymentEntity payment = new PaymentEntity();
        payment.id = UUID.randomUUID();
        payment.invoice = invoice;
        payment.amount = request.amount();
        payment.mode = request.mode();
        payment.reference = normalize(request.reference());
        payment.status = "VALIDATED";
        payment.createdAt = Instant.now();
        return payment;
    }

    private static String normalize(String value) {
        if (value == null || value.trim().isEmpty()) {
            return null;
        }
        return value.trim();
    }
}
