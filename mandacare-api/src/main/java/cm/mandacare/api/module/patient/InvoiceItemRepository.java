package cm.mandacare.api.module.patient;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

interface InvoiceItemRepository extends JpaRepository<InvoiceItemEntity, UUID> {
    List<InvoiceItemEntity> findByInvoiceId(UUID invoiceId);
}
