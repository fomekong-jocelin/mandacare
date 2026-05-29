package cm.mandacare.api.module.patient;

import org.springframework.stereotype.Component;

@Component
class VitalsMapper {

    VitalsResponse toResponse(VitalsEntity vitals) {
        return new VitalsResponse(
                vitals.id(),
                vitals.visitId(),
                vitals.patientId(),
                vitals.temperature(),
                vitals.systolicPressure(),
                vitals.diastolicPressure(),
                vitals.pulse(),
                vitals.respiratoryRate(),
                vitals.oxygenSaturation(),
                vitals.weight(),
                vitals.height(),
                vitals.bmi(),
                vitals.bloodGlucose(),
                vitals.createdAt()
        );
    }
}
