package cm.mandacare.api.module.patient;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

interface BenefitRepository extends JpaRepository<BenefitEntity, UUID> {
    Optional<BenefitEntity> findByCode(String code);
}
