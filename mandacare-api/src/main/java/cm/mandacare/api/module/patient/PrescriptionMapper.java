package cm.mandacare.api.module.patient;

import org.springframework.stereotype.Component;
import java.util.List;

@Component
class PrescriptionMapper {

    PrescriptionResponse toResponse(PrescriptionEntity entity) {
        List<PrescriptionItemResponse> items = entity.items().stream()
                .map(this::toResponse)
                .toList();

        return new PrescriptionResponse(
                entity.id(),
                entity.patient().id(),
                entity.consultation().id(),
                entity.prescriptionNumber(),
                entity.prescripteurId(),
                entity.status(),
                entity.pdfUrl() != null ? entity.pdfUrl() : "/api/v1/consultations/" + entity.consultation().id() + "/prescription/pdf",
                entity.qrCode(),
                entity.createdAt(),
                entity.validatedAt(),
                items
        );
    }

    PrescriptionItemResponse toResponse(PrescriptionItemEntity entity) {
        return new PrescriptionItemResponse(
                entity.id(),
                entity.drugName(),
                entity.form(),
                entity.dosage(),
                entity.frequency(),
                entity.duration(),
                entity.quantity(),
                entity.instructions()
        );
    }
}
