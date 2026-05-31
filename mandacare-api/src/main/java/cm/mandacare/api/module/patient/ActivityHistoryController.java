package cm.mandacare.api.module.patient;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import java.time.LocalDate;
import java.util.List;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@Validated
@RestController
@RequestMapping("/api/v1/activity")
@PreAuthorize("hasAnyRole('ADMIN','MEDECIN','INFIRMIER','CAISSIER','LABORATOIRE','ACCUEIL')")
class ActivityHistoryController {

    private final ActivityHistoryService service;

    ActivityHistoryController(ActivityHistoryService service) {
        this.service = service;
    }

    @GetMapping("/consultations")
    @PreAuthorize("hasAnyRole('ADMIN','MEDECIN','INFIRMIER')")
    List<ConsultationHistoryItemResponse> consultations(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
            @RequestParam(defaultValue = "50") @Min(1) @Max(100) int limit
    ) {
        return service.consultations(from, to, limit);
    }

    @GetMapping("/cash-desk")
    @PreAuthorize("hasAnyRole('ADMIN','CAISSIER')")
    List<CashDeskHistoryItemResponse> cashDesk(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
            @RequestParam(defaultValue = "50") @Min(1) @Max(100) int limit
    ) {
        return service.cashDesk(from, to, limit);
    }
}
