package cm.mandacare.api.module.patient;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

interface StockMovementRepository extends JpaRepository<StockMovementEntity, UUID> {
    List<StockMovementEntity> findAllByPharmacyItemIdOrderByCreatedAtDesc(UUID itemId);
}
