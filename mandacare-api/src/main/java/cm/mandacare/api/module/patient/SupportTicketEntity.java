package cm.mandacare.api.module.patient;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "support_tickets")
class SupportTicketEntity {

    @Id
    private UUID id;

    @Column(nullable = false, length = 150)
    private String subject;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String description;

    @Column(nullable = false, length = 50)
    private String category; // BUG, QUESTION, REQUEST

    @Column(nullable = false, length = 20)
    private String priority; // LOW, MEDIUM, HIGH, URGENT

    @Column(nullable = false, length = 20)
    private String status; // OPEN, RESOLVED

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    protected SupportTicketEntity() {
    }

    static SupportTicketEntity create(
            String subject,
            String description,
            String category,
            String priority,
            UUID userId
    ) {
        SupportTicketEntity ticket = new SupportTicketEntity();
        ticket.id = UUID.randomUUID();
        ticket.subject = subject.trim();
        ticket.description = description.trim();
        ticket.category = category;
        ticket.priority = priority;
        ticket.status = "OPEN";
        ticket.createdAt = Instant.now();
        ticket.userId = userId;
        return ticket;
    }

    void resolve() {
        this.status = "RESOLVED";
    }

    UUID id() { return id; }
    String subject() { return subject; }
    String description() { return description; }
    String category() { return category; }
    String priority() { return priority; }
    String status() { return status; }
    Instant createdAt() { return createdAt; }
    UUID userId() { return userId; }
}
