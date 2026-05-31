package cm.mandacare.api.module.patient;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

interface SupportTicketRepository extends JpaRepository<SupportTicketEntity, UUID> {
    List<SupportTicketEntity> findAllByUserIdOrderByCreatedAtDesc(UUID userId);
    List<SupportTicketEntity> findAllByOrderByCreatedAtDesc();
}
