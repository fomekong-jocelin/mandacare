package cm.mandacare.api.module.patient;

import jakarta.validation.Valid;
import java.net.URI;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

@RestController
@RequestMapping("/api/v1/visits/{visitId}/vitals")
class VitalsController {

    private final VitalsService service;

    VitalsController(VitalsService service) {
        this.service = service;
    }

    @PostMapping
    ResponseEntity<VitalsResponse> create(
            @PathVariable UUID visitId,
            @Valid @RequestBody CreateVitalsRequest request
    ) {
        VitalsResponse response = service.create(visitId, request);
        URI location = ServletUriComponentsBuilder
                .fromCurrentRequest()
                .path("/{id}")
                .buildAndExpand(response.id())
                .toUri();
        return ResponseEntity.created(location).body(response);
    }

    @GetMapping("/latest")
    VitalsResponse latest(@PathVariable UUID visitId) {
        return service.latest(visitId);
    }
}
