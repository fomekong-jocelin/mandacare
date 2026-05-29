package cm.mandacare.api.module.patient;

import jakarta.validation.Valid;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/consultations/{consultationId}/prescription")
class PrescriptionController {

    private final PrescriptionService service;
    private final PrescriptionPdfService pdfService;
    private final PrescriptionRepository repository;

    PrescriptionController(PrescriptionService service, PrescriptionPdfService pdfService, PrescriptionRepository repository) {
        this.service = service;
        this.pdfService = pdfService;
        this.repository = repository;
    }

    @GetMapping
    ResponseEntity<PrescriptionResponse> get(@PathVariable UUID consultationId) {
        return ResponseEntity.ok(service.getByConsultationId(consultationId));
    }

    @PostMapping
    ResponseEntity<PrescriptionResponse> save(
            @PathVariable UUID consultationId,
            @Valid @RequestBody CreatePrescriptionRequest request
    ) {
        return ResponseEntity.ok(service.save(consultationId, request));
    }

    @GetMapping("/pdf")
    @Transactional(readOnly = true)
    ResponseEntity<byte[]> getPdf(@PathVariable UUID consultationId) {
        PrescriptionEntity prescription = repository.findByConsultationId(consultationId)
                .orElseThrow(() -> new cm.mandacare.api.common.error.BusinessException(
                        "PRESCRIPTION_NOT_FOUND",
                        "Ordonnance introuvable pour cette consultation.",
                        org.springframework.http.HttpStatus.NOT_FOUND
                ));

        byte[] pdfBytes = pdfService.generatePdf(prescription);
        
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_PDF);
        headers.setContentDispositionFormData("inline", "ordonnance-" + prescription.prescriptionNumber() + ".pdf");
        headers.setCacheControl("must-revalidate, post-check=0, pre-check=0");
        
        return ResponseEntity.ok()
                .headers(headers)
                .body(pdfBytes);
    }
}
