package cm.mandacare.api.module.patient;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record CreateConsultationRequest(
        @Size(max = 2000) String symptoms,
        @Size(max = 2000) String clinicalExam,
        @Size(max = 1000) String diagnosis,
        @Size(max = 2000) String advice,
        @Size(max = 2000) String confidentialNotes,
        @NotNull ConsultationDecision decision,
        ConsultationStatus status,
        @Size(max = 1000) String correctionMotif
) {
    public ConsultationStatus getStatusOrDefault() {
        return status == null ? ConsultationStatus.VALIDATED : status;
    }
}
