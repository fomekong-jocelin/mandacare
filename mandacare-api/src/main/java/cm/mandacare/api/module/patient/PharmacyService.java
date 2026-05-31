package cm.mandacare.api.module.patient;

import cm.mandacare.api.common.error.BusinessException;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
class PharmacyService {

    private final PharmacyItemRepository items;
    private final StockMovementRepository movements;
    private final JdbcTemplate jdbcTemplate;

    PharmacyService(
            PharmacyItemRepository items,
            StockMovementRepository movements,
            JdbcTemplate jdbcTemplate
    ) {
        this.items = items;
        this.movements = movements;
        this.jdbcTemplate = jdbcTemplate;
    }

    @Transactional
    public PharmacyItemResponse create(CreatePharmacyItemRequest request) {
        if (items.findByCodeIgnoreCase(request.code()).isPresent()) {
            throw new BusinessException(
                    "DUPLICATE_CODE",
                    "Un médicament avec ce code existe déjà.",
                    HttpStatus.CONFLICT
            );
        }
        PharmacyItemEntity item = PharmacyItemEntity.create(
                request.code(),
                request.label(),
                request.dosage(),
                request.price(),
                request.alertThreshold()
        );
        return mapToResponse(items.save(item));
    }

    @Transactional
    public PharmacyItemResponse update(UUID id, CreatePharmacyItemRequest request) {
        PharmacyItemEntity item = items.findById(id)
                .orElseThrow(() -> new BusinessException(
                        "ITEM_NOT_FOUND",
                        "Médicament introuvable.",
                        HttpStatus.NOT_FOUND
                ));
        if (items.existsByCodeIgnoreCaseAndIdNot(request.code(), id)) {
            throw new BusinessException(
                    "DUPLICATE_CODE",
                    "Un médicament avec ce code existe déjà.",
                    HttpStatus.CONFLICT
            );
        }
        item.update(request.code(), request.label(), request.dosage(), request.price(), request.alertThreshold());
        return mapToResponse(items.save(item));
    }

    @Transactional(readOnly = true)
    public List<PharmacyItemResponse> listAll() {
        return items.findAllByOrderByLabelAsc().stream()
                .map(this::mapToResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<PharmacyItemResponse> listCritical() {
        return items.findCriticalItems().stream()
                .map(this::mapToResponse)
                .toList();
    }

    @Transactional
    public PharmacyItemResponse adjustStock(UUID id, StockAdjustmentRequest request) {
        PharmacyItemEntity item = items.findById(id)
                .orElseThrow(() -> new BusinessException(
                        "ITEM_NOT_FOUND",
                        "Médicament introuvable.",
                        HttpStatus.NOT_FOUND
                ));
        int quantity = request.quantity();
        String type = quantity >= 0 ? "IN" : "OUT";
        int absQty = Math.abs(quantity);

        item.adjustStock(quantity);
        items.save(item);

        UUID userId = getCurrentUserId();
        StockMovementEntity movement = StockMovementEntity.create(
                item,
                type,
                absQty,
                request.reason().trim(),
                userId
        );
        movements.save(movement);

        return mapToResponse(item);
    }

    @Transactional
    public void deductStockForPrescription(PrescriptionEntity prescription) {
        UUID userId = getCurrentUserId();
        for (PrescriptionItemEntity item : prescription.items()) {
            items.findByLabelIgnoreCase(item.drugName()).ifPresent(pharmacyItem -> {
                int quantityToDeduct = item.quantity() != null ? item.quantity() : 1;
                pharmacyItem.adjustStock(-quantityToDeduct);
                items.save(pharmacyItem);

                StockMovementEntity movement = StockMovementEntity.create(
                        pharmacyItem,
                        "OUT",
                        quantityToDeduct,
                        "Prescription N° " + prescription.prescriptionNumber(),
                        userId
                );
                movements.save(movement);
            });
        }
    }

    private PharmacyItemResponse mapToResponse(PharmacyItemEntity item) {
        return new PharmacyItemResponse(
                item.id(),
                item.code(),
                item.label(),
                item.dosage(),
                item.price(),
                item.stockQuantity(),
                item.alertThreshold(),
                item.isCritical()
        );
    }

    private UUID getCurrentUserId() {
        try {
            var auth = SecurityContextHolder.getContext().getAuthentication();
            if (auth == null || !auth.isAuthenticated() || "anonymousUser".equals(auth.getName())) {
                return null;
            }
            String username = auth.getName();
            return jdbcTemplate.queryForObject(
                    "SELECT id FROM auth_users WHERE LOWER(username) = LOWER(?)",
                    UUID.class,
                    username
            );
        } catch (Exception e) {
            return null;
        }
    }
}
