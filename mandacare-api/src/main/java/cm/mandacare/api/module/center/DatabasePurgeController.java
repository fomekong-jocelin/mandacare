package cm.mandacare.api.module.center;

import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/settings/database")
@PreAuthorize("hasRole('ADMIN')")
class DatabasePurgeController {

    private final DatabasePurgeService service;

    DatabasePurgeController(DatabasePurgeService service) {
        this.service = service;
    }

    @PostMapping("/purge")
    void purgeDatabase() {
        service.purge();
    }
}
