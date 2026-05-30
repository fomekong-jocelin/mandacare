package cm.mandacare.api.module.patient;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

interface PrescriptionRepository extends JpaRepository<PrescriptionEntity, UUID> {
    Optional<PrescriptionEntity> findByConsultationId(UUID consultationId);
    List<PrescriptionEntity> findAllByPatientIdOrderByCreatedAtDesc(UUID patientId);
    boolean existsByPrescriptionNumber(String prescriptionNumber);
    boolean existsByConsultationId(UUID consultationId);
}
