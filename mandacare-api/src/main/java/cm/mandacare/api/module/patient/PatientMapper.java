package cm.mandacare.api.module.patient;

import org.springframework.stereotype.Component;

@Component
class PatientMapper {

    PatientResponse toResponse(PatientEntity patient, VisitEntity latestVisit) {
        return new PatientResponse(
                patient.id(),
                patient.patientNumber(),
                patient.firstName(),
                patient.lastName(),
                patient.fullName(),
                patient.sex(),
                patient.birthDate(),
                patient.declaredAge(),
                patient.phone(),
                patient.city(),
                patient.district(),
                patient.emergencyContactName(),
                patient.emergencyContactPhone(),
                toVisitSummary(latestVisit),
                patient.createdAt()
        );
    }

    private VisitSummaryResponse toVisitSummary(VisitEntity visit) {
        if (visit == null) {
            return null;
        }
        return new VisitSummaryResponse(
                visit.id(),
                visit.reason(),
                visit.targetService(),
                visit.status(),
                visit.priority(),
                visit.arrivalAt()
        );
    }
}
