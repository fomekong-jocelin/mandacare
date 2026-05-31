package cm.mandacare.api.module.patient;

import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Validated
@RestController
@RequestMapping("/api/v1/pharmacy")
@PreAuthorize("hasAnyRole('ADMIN','MEDECIN','INFIRMIER','CAISSIER','LABORATOIRE','ACCUEIL')")
class PharmacyController {

    private final PharmacyService service;

    PharmacyController(PharmacyService service) {
        this.service = service;
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN','MEDECIN')")
    PharmacyItemResponse create(@Valid @RequestBody CreatePharmacyItemRequest request) {
        return service.create(request);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN','MEDECIN')")
    PharmacyItemResponse update(@PathVariable UUID id, @Valid @RequestBody CreatePharmacyItemRequest request) {
        return service.update(id, request);
    }

    @GetMapping
    List<PharmacyItemResponse> list() {
        return service.listAll();
    }

    @GetMapping("/critical")
    List<PharmacyItemResponse> listCritical() {
        return service.listCritical();
    }

    @PostMapping("/{id}/stock")
    PharmacyItemResponse adjustStock(
            @PathVariable UUID id,
            @Valid @RequestBody StockAdjustmentRequest request
    ) {
        return service.adjustStock(id, request);
    }
}
