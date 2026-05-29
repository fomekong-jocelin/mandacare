package cm.mandacare.api.module.patient;

import cm.mandacare.api.common.error.BusinessException;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
class VisitService {

    private final VisitRepository visits;
    private final PatientMapper mapper;

    VisitService(VisitRepository visits, PatientMapper mapper) {
        this.visits = visits;
        this.mapper = mapper;
    }

    @Transactional
    PatientResponse changeStatus(UUID visitId, UpdateVisitStatusRequest request) {
        VisitEntity visit = visits.findById(visitId)
                .orElseThrow(() -> new BusinessException(
                        "VISIT_NOT_FOUND",
                        "Visite introuvable.",
                        HttpStatus.NOT_FOUND
                ));
        visit.changeStatus(request.status());
        return mapper.toResponse(visit.patient(), visit);
    }
}
