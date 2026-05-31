package cm.mandacare.api.module.patient;

import jakarta.validation.constraints.NotBlank;

public record CreateSupportTicketRequest(
    @NotBlank String subject,
    @NotBlank String description,
    @NotBlank String category, // BUG, QUESTION, REQUEST
    @NotBlank String priority // LOW, MEDIUM, HIGH, URGENT
) {}
