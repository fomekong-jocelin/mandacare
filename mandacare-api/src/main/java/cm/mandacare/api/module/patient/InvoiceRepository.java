package cm.mandacare.api.module.patient;

import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

interface InvoiceRepository extends JpaRepository<InvoiceEntity, UUID> {
    boolean existsByInvoiceNumber(String invoiceNumber);
    boolean existsByVisitId(UUID visitId);
    java.util.Optional<InvoiceEntity> findByVisitId(UUID visitId);
}

