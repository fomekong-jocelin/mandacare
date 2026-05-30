package cm.mandacare.api.module.patient;

import cm.mandacare.api.common.error.BusinessException;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
class VisitService {

    private final VisitRepository visits;
    private final ConsultationRepository consultations;
    private final InvoiceRepository invoices;
    private final PaymentRepository payments;
    private final PatientMapper mapper;
    private final BenefitRepository benefits;
    private final ExamRequestRepository examRequests;

    VisitService(
            VisitRepository visits,
            ConsultationRepository consultations,
            InvoiceRepository invoices,
            PaymentRepository payments,
            PatientMapper mapper,
            BenefitRepository benefits,
            ExamRequestRepository examRequests
    ) {
        this.visits = visits;
        this.consultations = consultations;
        this.invoices = invoices;
        this.payments = payments;
        this.mapper = mapper;
        this.benefits = benefits;
        this.examRequests = examRequests;
    }

    @Transactional
    PatientResponse changeStatus(UUID visitId, UpdateVisitStatusRequest request) {
        VisitEntity visit = findVisit(visitId);
        VisitStatus nextStatus = request.status();
        if (!isAllowedManualTransition(visit.status(), nextStatus)) {
            throw new BusinessException(
                    "INVALID_VISIT_STATUS_TRANSITION",
                    "Cette transition de visite n'est pas autorisée manuellement.",
                    HttpStatus.BAD_REQUEST
            );
        }

        visit.changeStatus(nextStatus);
        return mapper.toResponse(visit.patient(), visit);
    }

    @Transactional
    PatientResponse completeCashDesk(UUID visitId, CashDeskPaymentRequest request) {
        VisitEntity visit = findVisit(visitId);
        if (visit.status() != VisitStatus.CASH_DESK) {
            throw new BusinessException(
                    "VISIT_NOT_AT_CASH_DESK",
                    "La visite n'est pas en attente de caisse.",
                    HttpStatus.BAD_REQUEST
            );
        }

        ConsultationEntity consultation = consultations.findByVisitId(visitId)
                .orElseThrow(() -> new BusinessException(
                        "CONSULTATION_DECISION_REQUIRED",
                        "Aucune décision médicale ne permet de finaliser la caisse.",
                        HttpStatus.BAD_REQUEST
                ));
        if (consultation.decision() == ConsultationDecision.KEEP_IN_CONSULTATION) {
            throw new BusinessException(
                    "CONSULTATION_DECISION_REQUIRED",
                    "La décision médicale ne permet pas encore une sortie de caisse.",
                    HttpStatus.BAD_REQUEST
            );
        }

        List<InvoiceItemEntity> items = new ArrayList<>();
        BigDecimal computedTotal = BigDecimal.ZERO;

        boolean consultationInvoiced = invoices.existsByVisitId(visitId);
        if (!consultationInvoiced) {
            BenefitEntity consPresta = benefits.findByCode("CONS_SIMPLE").orElse(null);
            BigDecimal consPrice = consPresta != null ? consPresta.price() : BigDecimal.valueOf(5000.00);
            String consName = consPresta != null ? consPresta.name() : "Consultation médicale";
            items.add(InvoiceItemEntity.forBenefit(consPresta, consPrice, 1));
            computedTotal = computedTotal.add(consPrice);
        }

        List<ExamRequestEntity> pendingRequests = examRequests.findByConsultationId(consultation.id()).stream()
                .filter(req -> "PRESCRIBED".equals(req.status()))
                .collect(Collectors.toList());

        for (ExamRequestEntity examReq : pendingRequests) {
            for (ExamRequestLineEntity line : examReq.lines()) {
                items.add(InvoiceItemEntity.forExam(line.exam(), line.price(), 1));
                computedTotal = computedTotal.add(line.price());
            }
            examReq.updateStatus("PAID");
            examRequests.save(examReq);
        }

        BigDecimal netAmount = computedTotal;
        BigDecimal paidAmount = request.amount();
        BigDecimal discount = BigDecimal.ZERO;

        InvoiceEntity invoice = invoices.save(InvoiceEntity.createDetailed(
                visit,
                nextInvoiceNumber(),
                computedTotal,
                discount,
                paidAmount,
                paidAmount.compareTo(netAmount) >= 0 ? "PAID" : "PARTIALLY_PAID",
                items
        ));

        payments.save(PaymentEntity.validatedFor(invoice, request));
        visit.changeStatus(consultation.decision().statusAfterCashDesk());
        return mapper.toResponse(visit.patient(), visit);
    }

    @Transactional(readOnly = true)
    InvoicePreviewResponse getInvoicePreview(UUID visitId) {
        VisitEntity visit = findVisit(visitId);
        List<InvoiceLineResponse> items = new ArrayList<>();
        BigDecimal total = BigDecimal.ZERO;

        boolean consultationInvoiced = invoices.existsByVisitId(visitId);
        if (!consultationInvoiced) {
            BenefitEntity consPresta = benefits.findByCode("CONS_SIMPLE").orElse(null);
            BigDecimal consPrice = consPresta != null ? consPresta.price() : BigDecimal.valueOf(5000.00);
            String consName = consPresta != null ? consPresta.name() : "Consultation médicale";
            items.add(new InvoiceLineResponse("BENEFIT", consName, consPrice, 1));
            total = total.add(consPrice);
        }

        ConsultationEntity consultation = consultations.findByVisitId(visitId).orElse(null);
        if (consultation != null) {
            List<ExamRequestEntity> pendingRequests = examRequests.findByConsultationId(consultation.id()).stream()
                    .filter(req -> "PRESCRIBED".equals(req.status()))
                    .collect(Collectors.toList());

            for (ExamRequestEntity examReq : pendingRequests) {
                for (ExamRequestLineEntity line : examReq.lines()) {
                    items.add(new InvoiceLineResponse("EXAM", line.exam().name(), line.price(), 1));
                    total = total.add(line.price());
                }
            }
        }

        return new InvoicePreviewResponse(total, BigDecimal.ZERO, total, items);
    }

    private String nextInvoiceNumber() {
        String invoiceNumber;
        do {
            invoiceNumber = "FAC-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
        } while (invoices.existsByInvoiceNumber(invoiceNumber));
        return invoiceNumber;
    }

    private boolean isAllowedManualTransition(VisitStatus currentStatus, VisitStatus nextStatus) {
        if (currentStatus == nextStatus) {
            return true;
        }

        return switch (currentStatus) {
            case WAITING -> nextStatus == VisitStatus.IN_CONSULTATION;
            case CASH_DESK -> nextStatus == VisitStatus.IN_CONSULTATION;
            case LAB -> nextStatus == VisitStatus.IN_CONSULTATION;
            case IN_CONSULTATION, RELEASED -> false;
        };
    }

    private VisitEntity findVisit(UUID visitId) {
        return visits.findById(visitId)
                .orElseThrow(() -> new BusinessException(
                        "VISIT_NOT_FOUND",
                        "Visite introuvable.",
                        HttpStatus.NOT_FOUND
                ));
    }
}
