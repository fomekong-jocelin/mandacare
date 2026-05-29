package cm.mandacare.api.module.patient;

import jakarta.validation.Valid;
import java.util.UUID;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/visits")
class VisitController {

    private final VisitService service;

    VisitController(VisitService service) {
        this.service = service;
    }

    @PatchMapping("/{id}/status")
    PatientResponse changeStatus(
            @PathVariable UUID id,
            @Valid @RequestBody UpdateVisitStatusRequest request
    ) {
        return service.changeStatus(id, request);
    }
}
