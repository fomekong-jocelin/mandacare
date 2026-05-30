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
@Table(name = "exam_request_lines")
class ExamRequestLineEntity {

    @Id
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "exam_request_id", nullable = false)
    private ExamRequestEntity examRequest;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "exam_id", nullable = false)
    private ExamEntity exam;

    @Column(nullable = false, precision = 12, scale = 2)
    private BigDecimal price;

    @Column(columnDefinition = "TEXT")
    private String comment;

    protected ExamRequestLineEntity() {
    }

    static ExamRequestLineEntity create(ExamEntity exam, BigDecimal price, String comment) {
        ExamRequestLineEntity line = new ExamRequestLineEntity();
        line.id = UUID.randomUUID();
        line.exam = exam;
        line.price = price;
        line.comment = comment;
        return line;
    }

    void setExamRequest(ExamRequestEntity examRequest) {
        this.examRequest = examRequest;
    }

    UUID id() {
        return id;
    }

    ExamRequestEntity examRequest() {
        return examRequest;
    }

    ExamEntity exam() {
        return exam;
    }

    BigDecimal price() {
        return price;
    }

    String comment() {
        return comment;
    }
}
