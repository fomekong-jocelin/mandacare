package cm.mandacare.api.module.patient;

import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

interface AuditLogRepository extends JpaRepository<AuditLogEntity, UUID> {
}
