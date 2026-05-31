package cm.mandacare.api.module.patient;

import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/reports")
@PreAuthorize("hasAnyRole('ADMIN','MEDECIN','CAISSIER')")
class ReportController {

    private final ReportService service;

    ReportController(ReportService service) {
        this.service = service;
    }

    @GetMapping("/daily")
    ReportResponse getDailyReport() {
        return service.getDailyReport();
    }
}
