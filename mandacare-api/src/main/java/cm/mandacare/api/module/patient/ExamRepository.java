package cm.mandacare.api.module.patient;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

interface ExamRepository extends JpaRepository<ExamEntity, UUID> {
    Optional<ExamEntity> findByCode(String code);
}
