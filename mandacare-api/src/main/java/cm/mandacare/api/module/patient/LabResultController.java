package cm.mandacare.api.module.patient;

import jakarta.validation.Valid;
import java.util.UUID;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/visits/{visitId}/lab-results")
class LabResultController {

    private final LabResultService service;
    private final LabResultRepository repository;
    private final LabResultPdfService pdfService;

    LabResultController(
            LabResultService service,
            LabResultRepository repository,
            LabResultPdfService pdfService
    ) {
        this.service = service;
        this.repository = repository;
        this.pdfService = pdfService;
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN','LABORATOIRE')")
    PatientResponse submit(
            @PathVariable UUID visitId,
            @Valid @RequestBody CreateLabResultRequest request
    ) {
        return service.submit(visitId, request);
    }

    @GetMapping("/pdf")
    @Transactional(readOnly = true)
    ResponseEntity<byte[]> getLatestPdf(@PathVariable UUID visitId) {
        LabResultEntity labResult = repository.findFirstByVisitIdOrderByCreatedAtDesc(visitId)
                .orElseThrow(() -> new cm.mandacare.api.common.error.BusinessException(
                        "LAB_RESULT_NOT_FOUND",
                        "Résultat de laboratoire introuvable pour cette visite.",
                        org.springframework.http.HttpStatus.NOT_FOUND
                ));

        byte[] pdfBytes = pdfService.generatePdf(labResult);

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_PDF);
        headers.setContentDispositionFormData("inline", "resultats-labo-" + labResult.resultNumber() + ".pdf");
        headers.setCacheControl("must-revalidate, post-check=0, pre-check=0");

        return ResponseEntity.ok()
                .headers(headers)
                .body(pdfBytes);
    }
}
