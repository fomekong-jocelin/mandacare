package cm.mandacare.api.module.patient;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "stock_movements")
class StockMovementEntity {

    @Id
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "pharmacy_item_id", nullable = false)
    private PharmacyItemEntity pharmacyItem;

    @Column(nullable = false, length = 10)
    private String type; // 'IN' ou 'OUT'

    @Column(nullable = false)
    private Integer quantity;

    @Column(length = 255)
    private String reason;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "user_id")
    private UUID userId;

    protected StockMovementEntity() {
    }

    static StockMovementEntity create(PharmacyItemEntity item, String type, Integer quantity, String reason, UUID userId) {
        StockMovementEntity mvmt = new StockMovementEntity();
        mvmt.id = UUID.randomUUID();
        mvmt.pharmacyItem = item;
        mvmt.type = type;
        mvmt.quantity = quantity;
        mvmt.reason = reason;
        mvmt.createdAt = Instant.now();
        mvmt.userId = userId;
        return mvmt;
    }

    UUID id() { return id; }
    PharmacyItemEntity pharmacyItem() { return pharmacyItem; }
    String type() { return type; }
    Integer quantity() { return quantity; }
    String reason() { return reason; }
    Instant createdAt() { return createdAt; }
    UUID userId() { return userId; }
}
