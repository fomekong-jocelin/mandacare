package cm.mandacare.api.module.patient;

import cm.mandacare.api.common.error.BusinessException;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
class LabResultService {

    private final VisitRepository visits;
    private final LabResultRepository labResults;
    private final PatientMapper mapper;

    LabResultService(
            VisitRepository visits,
            LabResultRepository labResults,
            PatientMapper mapper
    ) {
        this.visits = visits;
        this.labResults = labResults;
        this.mapper = mapper;
    }

    @Transactional
    PatientResponse submit(UUID visitId, CreateLabResultRequest request) {
        VisitEntity visit = findVisit(visitId);
        if (visit.status() != VisitStatus.LAB) {
            throw new BusinessException(
                    "VISIT_NOT_AT_LAB",
                    "La visite n'est pas en attente de résultats laboratoire.",
                    HttpStatus.BAD_REQUEST
            );
        }
        if (!request.isNormal() && isBlank(request.results())) {
            throw new BusinessException(
                    "LAB_RESULTS_REQUIRED",
                    "Les résultats de laboratoire sont requis.",
                    HttpStatus.BAD_REQUEST
            );
        }

        labResults.save(LabResultEntity.validatedFor(
                visit,
                nextResultNumber(),
                request
        ));
        visit.changeStatus(VisitStatus.IN_CONSULTATION);
        return mapper.toResponse(visit.patient(), visit);
    }

    private String nextResultNumber() {
        String resultNumber;
        do {
            resultNumber = "LAB-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
        } while (labResults.existsByResultNumber(resultNumber));
        return resultNumber;
    }

    private VisitEntity findVisit(UUID visitId) {
        return visits.findById(visitId)
                .orElseThrow(() -> new BusinessException(
                        "VISIT_NOT_FOUND",
                        "Visite introuvable.",
                        HttpStatus.NOT_FOUND
                ));
    }

    private static boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}
