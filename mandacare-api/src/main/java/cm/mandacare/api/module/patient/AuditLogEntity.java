package cm.mandacare.api.module.patient;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "audit_logs")
class AuditLogEntity {

    @Id
    private UUID id;

    @Column(name = "user_id")
    private UUID userId;

    @Column(nullable = false, length = 80)
    private String action;

    @Column(nullable = false, length = 80)
    private String module;

    @Column(name = "entity_type", length = 80)
    private String entityType;

    @Column(name = "entity_id")
    private UUID entityId;

    @Column(columnDefinition = "TEXT")
    private String reason;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    protected AuditLogEntity() {
    }

    static AuditLogEntity log(UUID userId, String action, String module, String entityType, UUID entityId, String reason) {
        AuditLogEntity log = new AuditLogEntity();
        log.id = UUID.randomUUID();
        log.userId = userId;
        log.action = action;
        log.module = module;
        log.entityType = entityType;
        log.entityId = entityId;
        log.reason = reason;
        log.createdAt = Instant.now();
        return log;
    }

    UUID id() {
        return id;
    }

    UUID userId() {
        return userId;
    }

    String action() {
        return action;
    }

    String module() {
        return module;
    }

    String entityType() {
        return entityType;
    }

    UUID entityId() {
        return entityId;
    }

    String reason() {
        return reason;
    }

    Instant createdAt() {
        return createdAt;
    }
}
