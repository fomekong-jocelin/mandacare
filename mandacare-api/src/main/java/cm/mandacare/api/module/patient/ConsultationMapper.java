package cm.mandacare.api.module.patient;

import org.springframework.stereotype.Component;

@Component
class ConsultationMapper {

    ConsultationResponse toResponse(
            ConsultationEntity consultation,
            VisitStatus visitStatus
    ) {
        return new ConsultationResponse(
                consultation.id(),
                consultation.visitId(),
                consultation.patientId(),
                consultation.reason(),
                consultation.symptoms(),
                consultation.clinicalExam(),
                consultation.finalDiagnosis(),
                consultation.advice(),
                consultation.status(),
                consultation.decision(),
                visitStatus,
                consultation.validatedAt(),
                consultation.createdAt()
        );
    }
}
