package cm.mandacare.api.module.patient;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

interface PharmacyItemRepository extends JpaRepository<PharmacyItemEntity, UUID> {
    Optional<PharmacyItemEntity> findByCodeIgnoreCase(String code);
    Optional<PharmacyItemEntity> findByLabelIgnoreCase(String label);

    @Query("SELECT p FROM PharmacyItemEntity p WHERE p.stockQuantity <= p.alertThreshold")
    List<PharmacyItemEntity> findCriticalItems();

    List<PharmacyItemEntity> findAllByOrderByLabelAsc();
}
