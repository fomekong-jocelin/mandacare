package cm.mandacare.api.module.patient;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.util.UUID;

@Entity
@Table(name = "pharmacy_items")
class PharmacyItemEntity {

    @Id
    private UUID id;

    @Column(nullable = false, unique = true, length = 50)
    private String code;

    @Column(nullable = false, length = 100)
    private String label;

    @Column(length = 50)
    private String dosage;

    @Column(nullable = false)
    private BigDecimal price;

    @Column(name = "stock_quantity", nullable = false)
    private Integer stockQuantity;

    @Column(name = "alert_threshold", nullable = false)
    private Integer alertThreshold;

    protected PharmacyItemEntity() {
    }

    static PharmacyItemEntity create(String code, String label, String dosage, BigDecimal price, Integer alertThreshold) {
        PharmacyItemEntity item = new PharmacyItemEntity();
        item.id = UUID.randomUUID();
        item.code = code.trim().toUpperCase();
        item.label = label.trim();
        item.dosage = dosage != null ? dosage.trim() : null;
        item.price = price;
        item.stockQuantity = 0;
        item.alertThreshold = alertThreshold != null ? alertThreshold : 5;
        return item;
    }

    void adjustStock(int qty) {
        this.stockQuantity += qty;
        if (this.stockQuantity < 0) {
            this.stockQuantity = 0;
        }
    }

    void update(String code, String label, String dosage, BigDecimal price, Integer alertThreshold) {
        this.code = code.trim().toUpperCase();
        this.label = label.trim();
        this.dosage = dosage != null ? dosage.trim() : null;
        this.price = price;
        this.alertThreshold = alertThreshold != null ? alertThreshold : 5;
    }

    UUID id() { return id; }
    String code() { return code; }
    String label() { return label; }
    String dosage() { return dosage; }
    BigDecimal price() { return price; }
    Integer stockQuantity() { return stockQuantity; }
    Integer alertThreshold() { return alertThreshold; }

    boolean isCritical() {
        return stockQuantity <= alertThreshold;
    }
}
