package cm.mandacare.api.module.patient;

import cm.mandacare.api.common.error.BusinessException;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
class ConsultationService {

    private final VisitRepository visits;
    private final ConsultationRepository consultations;
    private final ConsultationMapper mapper;
    private final AuditLogRepository auditLogs;

    ConsultationService(
            VisitRepository visits,
            ConsultationRepository consultations,
            ConsultationMapper mapper,
            AuditLogRepository auditLogs
    ) {
        this.visits = visits;
        this.consultations = consultations;
        this.mapper = mapper;
        this.auditLogs = auditLogs;
    }

    @Transactional
    ConsultationResponse create(UUID visitId, CreateConsultationRequest request) {
        VisitEntity visit = findVisit(visitId);
        ensureVisitCanBeConsulted(visit);

        ConsultationStatus nextStatus = request.getStatusOrDefault();
        if (nextStatus == ConsultationStatus.VALIDATED) {
            validateFieldsForValidation(request);
        }

        ConsultationEntity consultation = consultations.findByVisitId(visitId)
                .map(existing -> {
                    if (existing.status() == ConsultationStatus.VALIDATED || existing.status() == ConsultationStatus.CORRECTED) {
                        if (nextStatus == ConsultationStatus.DRAFT) {
                            throw new BusinessException(
                                    "CONSULTATION_ALREADY_VALIDATED",
                                    "Cette consultation est déjà validée et ne peut pas repasser en brouillon.",
                                    HttpStatus.CONFLICT
                            );
                        }
                        if (request.correctionMotif() == null || request.correctionMotif().trim().isEmpty()) {
                            throw new BusinessException(
                                    "CORRECTION_MOTIF_REQUIRED",
                                    "Un motif de correction est requis pour modifier une consultation validée.",
                                    HttpStatus.BAD_REQUEST
                            );
                        }
                        auditLogs.save(AuditLogEntity.log(
                                null,
                                "CORRECT_CONSULTATION",
                                "PATIENT",
                                "CONSULTATION",
                                existing.id(),
                                request.correctionMotif().trim()
                        ));
                        existing.markCorrected(request);
                    } else {
                        existing.update(request, nextStatus);
                    }
                    return consultations.save(existing);
                })
                .orElseGet(() -> consultations.save(ConsultationEntity.create(visit, request)));

        if (nextStatus == ConsultationStatus.VALIDATED) {
            visit.changeStatus(request.decision().visitStatus());
        } else {
            visit.markReadyForConsultation();
        }

        return mapper.toResponse(consultation, visit.status());
    }

    private void validateFieldsForValidation(CreateConsultationRequest request) {
        if (request.symptoms() == null || request.symptoms().trim().isEmpty()) {
            throw new BusinessException(
                    "SYMPTOMS_REQUIRED",
                    "Les symptômes sont requis pour valider la consultation.",
                    HttpStatus.BAD_REQUEST
            );
        }
        if (request.clinicalExam() == null || request.clinicalExam().trim().isEmpty()) {
            throw new BusinessException(
                    "CLINICAL_EXAM_REQUIRED",
                    "L'examen clinique est requis pour valider la consultation.",
                    HttpStatus.BAD_REQUEST
            );
        }
        if (request.diagnosis() == null || request.diagnosis().trim().isEmpty()) {
            throw new BusinessException(
                    "DIAGNOSIS_REQUIRED",
                    "Le diagnostic est requis pour valider la consultation.",
                    HttpStatus.BAD_REQUEST
            );
        }
    }

    private VisitEntity findVisit(UUID visitId) {
        return visits.findById(visitId)
                .orElseThrow(() -> new BusinessException(
                        "VISIT_NOT_FOUND",
                        "Visite introuvable.",
                        HttpStatus.NOT_FOUND
                ));
    }

    private void ensureVisitCanBeConsulted(VisitEntity visit) {
        if (visit.status() == VisitStatus.RELEASED) {
            throw new BusinessException(
                    "VISIT_ALREADY_CLOSED",
                    "Cette visite est déjà clôturée.",
                    HttpStatus.CONFLICT
            );
        }
    }
}
