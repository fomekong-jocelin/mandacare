package cm.mandacare.api.module.patient;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import java.net.URI;
import java.util.List;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

@Validated
@RestController
@RequestMapping("/api/v1/patients")
@PreAuthorize("hasAnyRole('ADMIN','MEDECIN','INFIRMIER','CAISSIER','LABORATOIRE','ACCUEIL')")
class PatientController {

    private final PatientService service;

    PatientController(PatientService service) {
        this.service = service;
    }

    @PostMapping
    ResponseEntity<PatientResponse> create(@Valid @RequestBody CreatePatientRequest request) {
        PatientResponse response = service.create(request);
        URI location = ServletUriComponentsBuilder
                .fromCurrentRequest()
                .path("/{id}")
                .buildAndExpand(response.id())
                .toUri();
        return ResponseEntity.created(location).body(response);
    }

    @GetMapping
    List<PatientResponse> list(
            @RequestParam(required = false) String search,
            @RequestParam(defaultValue = "50") @Min(1) @Max(100) int limit
    ) {
        return service.list(search, limit);
    }

    @GetMapping("/queue/today")
    List<PatientResponse> todayQueue(
            @RequestParam(defaultValue = "8") @Min(1) @Max(20) int limit,
            @RequestParam(required = false) VisitStatus status
    ) {
        return service.todayQueue(limit, status);
    }

    @GetMapping("/{id}")
    PatientResponse get(@PathVariable UUID id) {
        return service.get(id);
    }

    @GetMapping("/{id}/timeline")
    List<PatientTimelineItemResponse> getTimeline(@PathVariable UUID id) {
        return service.getTimeline(id);
    }

    @PostMapping("/{id}/visits")
    ResponseEntity<PatientResponse> createVisit(
            @PathVariable UUID id,
            @Valid @RequestBody CreateVisitRequest request
    ) {
        PatientResponse response = service.createVisit(id, request);
        URI location = ServletUriComponentsBuilder
                .fromCurrentRequest()
                .path("/{visitId}")
                .buildAndExpand(response.latestVisit().id())
                .toUri();
        return ResponseEntity.created(location).body(response);
    }

    @PostMapping("/share-log")
    ResponseEntity<Void> logShare(@Valid @RequestBody ShareLogRequest request) {
        service.logShare(request);
        return ResponseEntity.ok().build();
    }
}
