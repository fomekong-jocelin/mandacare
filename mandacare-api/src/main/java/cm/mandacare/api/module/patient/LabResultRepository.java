package cm.mandacare.api.module.patient;

import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

interface LabResultRepository extends JpaRepository<LabResultEntity, UUID> {

    boolean existsByResultNumber(String resultNumber);
    java.util.List<LabResultEntity> findByVisitId(UUID visitId);
}
