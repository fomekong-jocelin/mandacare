package cm.mandacare.api.module.patient;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.util.UUID;

@Entity
@Table(name = "exams")
class ExamEntity {

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

    protected ExamEntity() {
    }

    static ExamEntity create(UUID id, String code, String name, String category, BigDecimal price) {
        ExamEntity exam = new ExamEntity();
        exam.id = id;
        exam.code = code;
        exam.name = name;
        exam.category = category;
        exam.price = price;
        exam.active = true;
        return exam;
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
