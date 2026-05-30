package cm.mandacare.api.module.patient;

import jakarta.validation.Valid;
import java.net.URI;
import java.util.List;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

@RestController
@RequestMapping("/api/v1/tariff")
@PreAuthorize("hasRole('ADMIN')")
class TariffAdminController {

    private final TariffAdminService service;

    TariffAdminController(TariffAdminService service) {
        this.service = service;
    }

    // ─── Exams (labo) ────────────────────────────────────────────────────────────

    @GetMapping("/exams")
    List<ExamResponse> listExams() {
        return service.listAllExams();
    }

    @PostMapping("/exams")
    ResponseEntity<ExamResponse> createExam(@Valid @RequestBody CreateTariffItemRequest request) {
        ExamResponse response = service.createExam(request);
        URI location = ServletUriComponentsBuilder
                .fromCurrentRequest()
                .path("/{id}")
                .buildAndExpand(response.id())
                .toUri();
        return ResponseEntity.created(location).body(response);
    }

    @PatchMapping("/exams/{id}")
    ExamResponse updateExam(
            @PathVariable UUID id,
            @Valid @RequestBody UpdateTariffItemRequest request
    ) {
        return service.updateExam(id, request);
    }

    // ─── Benefits (soins / actes médicaux) ───────────────────────────────────────

    @GetMapping("/benefits")
    List<BenefitResponse> listBenefits() {
        return service.listAllBenefits();
    }

    @PostMapping("/benefits")
    ResponseEntity<BenefitResponse> createBenefit(@Valid @RequestBody CreateTariffItemRequest request) {
        BenefitResponse response = service.createBenefit(request);
        URI location = ServletUriComponentsBuilder
                .fromCurrentRequest()
                .path("/{id}")
                .buildAndExpand(response.id())
                .toUri();
        return ResponseEntity.created(location).body(response);
    }

    @PatchMapping("/benefits/{id}")
    BenefitResponse updateBenefit(
            @PathVariable UUID id,
            @Valid @RequestBody UpdateTariffItemRequest request
    ) {
        return service.updateBenefit(id, request);
    }
}
