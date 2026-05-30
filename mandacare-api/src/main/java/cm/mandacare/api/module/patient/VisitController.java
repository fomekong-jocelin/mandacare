package cm.mandacare.api.module.patient;

import jakarta.validation.Valid;
import java.util.UUID;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/visits")
class VisitController {

    private final VisitService service;
    private final InvoiceRepository invoiceRepository;
    private final InvoicePdfService invoicePdfService;

    VisitController(VisitService service, InvoiceRepository invoiceRepository, InvoicePdfService invoicePdfService) {
        this.service = service;
        this.invoiceRepository = invoiceRepository;
        this.invoicePdfService = invoicePdfService;
    }

    @PatchMapping("/{id}/status")
    @PreAuthorize("hasAnyRole('ADMIN','MEDECIN','INFIRMIER','CAISSIER','LABORATOIRE')")
    PatientResponse changeStatus(
            @PathVariable UUID id,
            @Valid @RequestBody UpdateVisitStatusRequest request
    ) {
        return service.changeStatus(id, request);
    }

    @PatchMapping("/{id}/cash-desk/complete")
    @PreAuthorize("hasAnyRole('ADMIN','CAISSIER')")
    PatientResponse completeCashDesk(
            @PathVariable UUID id,
            @Valid @RequestBody CashDeskPaymentRequest request
    ) {
        return service.completeCashDesk(id, request);
    }

    @org.springframework.web.bind.annotation.GetMapping("/{id}/invoice-preview")
    @PreAuthorize("hasAnyRole('ADMIN','CAISSIER')")
    InvoicePreviewResponse getInvoicePreview(@PathVariable UUID id) {
        return service.getInvoicePreview(id);
    }

    @org.springframework.web.bind.annotation.GetMapping("/{id}/invoice/pdf")
    @org.springframework.transaction.annotation.Transactional(readOnly = true)
    org.springframework.http.ResponseEntity<byte[]> getInvoicePdf(@PathVariable UUID id) {
        java.util.List<InvoiceEntity> invoices = invoiceRepository.findByVisitIdOrderByCreatedAtDesc(id);
        if (invoices.isEmpty()) {
            throw new cm.mandacare.api.common.error.BusinessException(
                    "INVOICE_NOT_FOUND",
                    "Facture introuvable pour cette visite.",
                    org.springframework.http.HttpStatus.NOT_FOUND
            );
        }
        InvoiceEntity invoice = invoices.get(0);

        byte[] pdfBytes = invoicePdfService.generatePdf(invoice);

        org.springframework.http.HttpHeaders headers = new org.springframework.http.HttpHeaders();
        headers.setContentType(org.springframework.http.MediaType.APPLICATION_PDF);
        headers.setContentDispositionFormData("inline", "facture-" + invoice.invoiceNumber() + ".pdf");
        headers.setCacheControl("must-revalidate, post-check=0, pre-check=0");

        return org.springframework.http.ResponseEntity.ok()
                .headers(headers)
                .body(pdfBytes);
    }

    @org.springframework.web.bind.annotation.GetMapping("/{id}/invoices")
    @org.springframework.transaction.annotation.Transactional(readOnly = true)
    @PreAuthorize("hasAnyRole('ADMIN','CAISSIER')")
    java.util.List<InvoiceResponse> getInvoices(@PathVariable UUID id) {
        java.util.List<InvoiceEntity> invoices = invoiceRepository.findByVisitIdOrderByCreatedAtDesc(id);
        return invoices.stream().map(invoice -> new InvoiceResponse(
                invoice.id(),
                invoice.invoiceNumber(),
                invoice.totalAmount(),
                invoice.discount(),
                invoice.netAmount(),
                invoice.paidAmount(),
                invoice.remainingAmount(),
                invoice.status(),
                invoice.createdAt(),
                invoice.items().stream().map(item -> new InvoiceLineResponse(
                        item.type(),
                        item.label(),
                        item.price(),
                        item.quantity()
                )).toList()
        )).toList();
    }
}
