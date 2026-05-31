package cm.mandacare.api.module.patient;

import cm.mandacare.api.common.error.BusinessException;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
class PrescriptionService {

    private final PrescriptionRepository prescriptions;
    private final ConsultationRepository consultations;
    private final PrescriptionNumberGenerator numberGenerator;
    private final PrescriptionMapper mapper;
    private final JdbcTemplate jdbcTemplate;
    private final PharmacyService pharmacyService;

    PrescriptionService(
            PrescriptionRepository prescriptions,
            ConsultationRepository consultations,
            PrescriptionNumberGenerator numberGenerator,
            PrescriptionMapper mapper,
            JdbcTemplate jdbcTemplate,
            PharmacyService pharmacyService
    ) {
        this.prescriptions = prescriptions;
        this.consultations = consultations;
        this.numberGenerator = numberGenerator;
        this.mapper = mapper;
        this.jdbcTemplate = jdbcTemplate;
        this.pharmacyService = pharmacyService;
    }

    @Transactional(readOnly = true)
    public PrescriptionResponse getByConsultationId(UUID consultationId) {
        PrescriptionEntity prescription = prescriptions.findByConsultationId(consultationId)
                .orElseThrow(() -> new BusinessException(
                        "PRESCRIPTION_NOT_FOUND",
                        "Ordonnance introuvable pour cette consultation.",
                        HttpStatus.NOT_FOUND
                ));
        return mapper.toResponse(prescription);
    }

    @Transactional
    public PrescriptionResponse save(UUID consultationId, CreatePrescriptionRequest request) {
        ConsultationEntity consultation = consultations.findById(consultationId)
                .orElseThrow(() -> new BusinessException(
                        "CONSULTATION_NOT_FOUND",
                        "Consultation introuvable.",
                        HttpStatus.NOT_FOUND
                ));

        PrescriptionStatus nextStatus = request.status();
        if (nextStatus == PrescriptionStatus.VALIDATED) {
            validateFieldsForValidation(request);
        }

        PrescriptionEntity prescription = prescriptions.findByConsultationId(consultationId)
                .map(existing -> {
                    if (existing.status() == PrescriptionStatus.VALIDATED || existing.status() == PrescriptionStatus.SENT || existing.status() == PrescriptionStatus.PRINTED) {
                        if (nextStatus == PrescriptionStatus.DRAFT) {
                            throw new BusinessException(
                                    "PRESCRIPTION_ALREADY_VALIDATED",
                                    "Cette ordonnance est déjà validée et ne peut pas repasser en brouillon.",
                                    HttpStatus.CONFLICT
                            );
                        }
                        if (consultation.status() == ConsultationStatus.VALIDATED) {
                            throw new BusinessException(
                                    "PRESCRIPTION_LOCKED",
                                    "L'ordonnance est verrouillée car la consultation correspondante est validée.",
                                    HttpStatus.CONFLICT
                            );
                        }
                    }

                    boolean isValidating = existing.status() == PrescriptionStatus.DRAFT && nextStatus == PrescriptionStatus.VALIDATED;

                    existing.updateStatus(nextStatus);
                    existing.items().clear();
                    if (request.items() != null) {
                        for (CreatePrescriptionItemRequest itemReq : request.items()) {
                            existing.addItem(PrescriptionItemEntity.create(
                                    itemReq.drugName(),
                                    itemReq.form(),
                                    itemReq.dosage(),
                                    itemReq.frequency(),
                                    itemReq.duration(),
                                    itemReq.quantity(),
                                    itemReq.instructions()
                             ));
                        }
                    }
                    PrescriptionEntity saved = prescriptions.save(existing);
                    if (isValidating) {
                        pharmacyService.deductStockForPrescription(saved);
                    }
                    return saved;
                })
                .orElseGet(() -> {
                    String prescriptionNumber = numberGenerator.next();
                    UUID prescripteurId = getCurrentUserId();
                    PrescriptionEntity newPrescription = PrescriptionEntity.create(
                            consultation.patient(),
                            consultation,
                            prescriptionNumber,
                            prescripteurId,
                            nextStatus
                    );
                    if (request.items() != null) {
                        for (CreatePrescriptionItemRequest itemReq : request.items()) {
                            newPrescription.addItem(PrescriptionItemEntity.create(
                                    itemReq.drugName(),
                                    itemReq.form(),
                                    itemReq.dosage(),
                                    itemReq.frequency(),
                                    itemReq.duration(),
                                    itemReq.quantity(),
                                    itemReq.instructions()
                            ));
                        }
                    }
                    PrescriptionEntity saved = prescriptions.save(newPrescription);
                    if (nextStatus == PrescriptionStatus.VALIDATED) {
                        pharmacyService.deductStockForPrescription(saved);
                    }
                    return saved;
                });

        return mapper.toResponse(prescription);
    }

    private void validateFieldsForValidation(CreatePrescriptionRequest request) {
        if (request.items() == null || request.items().isEmpty()) {
            throw new BusinessException(
                    "PRESCRIPTION_ITEMS_REQUIRED",
                    "Au moins un médicament est requis pour valider l'ordonnance.",
                    HttpStatus.BAD_REQUEST
            );
        }
        for (CreatePrescriptionItemRequest item : request.items()) {
            if (item.drugName() == null || item.drugName().trim().isEmpty()) {
                throw new BusinessException(
                        "DRUG_NAME_REQUIRED",
                        "Le nom du médicament est requis pour chaque ligne d'ordonnance.",
                        HttpStatus.BAD_REQUEST
                );
            }
        }
    }

    private UUID getCurrentUserId() {
        try {
            var auth = SecurityContextHolder.getContext().getAuthentication();
            if (auth == null || !auth.isAuthenticated() || "anonymousUser".equals(auth.getName())) {
                return null;
            }
            String username = auth.getName();
            return jdbcTemplate.queryForObject(
                    "SELECT id FROM auth_users WHERE LOWER(username) = LOWER(?)",
                    UUID.class,
                    username
            );
        } catch (Exception e) {
            return null;
        }
    }
}
