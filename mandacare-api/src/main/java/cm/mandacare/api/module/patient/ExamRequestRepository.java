package cm.mandacare.api.module.patient;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

interface ExamRequestRepository extends JpaRepository<ExamRequestEntity, UUID> {
    Optional<ExamRequestEntity> findByRequestNumber(String requestNumber);
    List<ExamRequestEntity> findByConsultationId(UUID consultationId);
    List<ExamRequestEntity> findByPatientId(UUID patientId);
}
