package cm.mandacare.api.module.patient;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public record PrescriptionResponse(
        UUID id,
        UUID patientId,
        UUID consultationId,
        String prescriptionNumber,
        UUID prescripteurId,
        PrescriptionStatus status,
        String pdfUrl,
        String qrCode,
        Instant createdAt,
        Instant validatedAt,
        List<PrescriptionItemResponse> items
) {}
