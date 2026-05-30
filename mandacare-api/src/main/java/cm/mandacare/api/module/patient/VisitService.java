package cm.mandacare.api.module.patient;

import cm.mandacare.api.common.error.BusinessException;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
class VisitService {

    private final VisitRepository visits;
    private final ConsultationRepository consultations;
    private final PatientMapper mapper;

    VisitService(VisitRepository visits, ConsultationRepository consultations, PatientMapper mapper) {
        this.visits = visits;
        this.consultations = consultations;
        this.mapper = mapper;
    }

    @Transactional
    PatientResponse changeStatus(UUID visitId, UpdateVisitStatusRequest request) {
        VisitEntity visit = findVisit(visitId);
        visit.changeStatus(request.status());
        return mapper.toResponse(visit.patient(), visit);
    }

    @Transactional
    PatientResponse completeCashDesk(UUID visitId) {
        VisitEntity visit = findVisit(visitId);
        if (visit.status() != VisitStatus.CASH_DESK) {
            throw new BusinessException(
                    "VISIT_NOT_AT_CASH_DESK",
                    "La visite n'est pas en attente de caisse.",
                    HttpStatus.BAD_REQUEST
            );
        }

        ConsultationEntity consultation = consultations.findByVisitId(visitId)
                .orElseThrow(() -> new BusinessException(
                        "CONSULTATION_DECISION_REQUIRED",
                        "Aucune décision médicale ne permet de finaliser la caisse.",
                        HttpStatus.BAD_REQUEST
                ));
        if (consultation.decision() == ConsultationDecision.KEEP_IN_CONSULTATION) {
            throw new BusinessException(
                    "CONSULTATION_DECISION_REQUIRED",
                    "La décision médicale ne permet pas encore une sortie de caisse.",
                    HttpStatus.BAD_REQUEST
            );
        }

        visit.changeStatus(consultation.decision().statusAfterCashDesk());
        return mapper.toResponse(visit.patient(), visit);
    }

    private VisitEntity findVisit(UUID visitId) {
        return visits.findById(visitId)
                .orElseThrow(() -> new BusinessException(
                        "VISIT_NOT_FOUND",
                        "Visite introuvable.",
                        HttpStatus.NOT_FOUND
                ));
    }
}
