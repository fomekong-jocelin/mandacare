package cm.mandacare.api.module.dashboard;

import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/dashboard")
@PreAuthorize("hasAnyRole('ADMIN','MEDECIN','INFIRMIER','CAISSIER','LABORATOIRE','ACCUEIL','AUTRE')")
class DashboardController {

    private final DashboardService service;

    DashboardController(DashboardService service) {
        this.service = service;
    }

    @GetMapping("/today")
    DashboardTodayResponse today() {
        return service.today();
    }
}
