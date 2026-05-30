package cm.mandacare.api.module.patient;

import jakarta.validation.Valid;
import java.util.UUID;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/visits/{visitId}/lab-results")
class LabResultController {

    private final LabResultService service;

    LabResultController(LabResultService service) {
        this.service = service;
    }

    @PostMapping
    PatientResponse submit(
            @PathVariable UUID visitId,
            @Valid @RequestBody CreateLabResultRequest request
    ) {
        return service.submit(visitId, request);
    }
}
