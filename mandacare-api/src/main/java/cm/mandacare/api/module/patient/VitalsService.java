package cm.mandacare.api.module.patient;

import cm.mandacare.api.common.error.BusinessException;
import java.util.UUID;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
class VitalsService {

    private final VisitRepository visits;
    private final VitalsRepository vitals;
    private final VitalsMapper mapper;

    VitalsService(VisitRepository visits, VitalsRepository vitals, VitalsMapper mapper) {
        this.visits = visits;
        this.vitals = vitals;
        this.mapper = mapper;
    }

    @Transactional
    VitalsResponse create(UUID visitId, CreateVitalsRequest request) {
        VisitEntity visit = findVisit(visitId);
        VitalsEntity savedVitals = vitals.save(VitalsEntity.create(visit, request));
        visit.markReadyForConsultation();
        return mapper.toResponse(savedVitals);
    }

    @Transactional(readOnly = true)
    VitalsResponse latest(UUID visitId) {
        return vitals.findLatestCandidates(visitId, PageRequest.of(0, 1))
                .stream()
                .findFirst()
                .map(mapper::toResponse)
                .orElseThrow(() -> new BusinessException(
                        "VITALS_NOT_FOUND",
                        "Constantes introuvables.",
                        HttpStatus.NOT_FOUND
                ));
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
