package cm.mandacare.api.module.health;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/health")
class HealthController {

    @GetMapping
    HealthStatusResponse health() {
        return new HealthStatusResponse("UP", "mandacare-api");
    }
}

