package cm.mandacare.api.module.patient;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.util.UUID;

@Entity
@Table(name = "benefits")
class BenefitEntity {

    @Id
    private UUID id;

    @Column(nullable = false, unique = true, length = 60)
    private String code;

    @Column(nullable = false, length = 180)
    private String name;

    @Column(length = 120)
    private String category;

    @Column(nullable = false, precision = 12, scale = 2)
    private BigDecimal price;

    @Column(nullable = false)
    private boolean active;

    protected BenefitEntity() {
    }

    static BenefitEntity create(UUID id, String code, String name, String category, BigDecimal price) {
        BenefitEntity benefit = new BenefitEntity();
        benefit.id = id;
        benefit.code = code;
        benefit.name = name;
        benefit.category = category;
        benefit.price = price;
        benefit.active = true;
        return benefit;
    }

    UUID id() {
        return id;
    }

    String code() {
        return code;
    }

    String name() {
        return name;
    }

    String category() {
        return category;
    }

    BigDecimal price() {
        return price;
    }

    boolean isActive() {
        return active;
    }

    void update(String name, String category, BigDecimal price, boolean active) {
        this.name = name;
        this.category = category;
        this.price = price;
        this.active = active;
    }
}
