package cm.mandacare.api.module.patient;

import java.time.Instant;
import java.util.UUID;

public record SupportTicketResponse(
    UUID id,
    String subject,
    String description,
    String category,
    String priority,
    String status,
    Instant createdAt,
    UUID userId
) {}
