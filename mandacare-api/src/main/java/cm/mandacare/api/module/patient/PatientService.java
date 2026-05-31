package cm.mandacare.api.module.patient;

import cm.mandacare.api.common.error.BusinessException;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
class PatientService {

    private final PatientRepository patients;
    private final VisitRepository visits;
    private final PatientNumberGenerator patientNumbers;
    private final PatientMapper mapper;
    private final Clock clock;
    private final VitalsRepository vitalsRepository;
    private final ConsultationRepository consultationRepository;
    private final VitalsMapper vitalsMapper;
    private final ConsultationMapper consultationMapper;
    private final PrescriptionRepository prescriptionRepository;
    private final LabResultRepository labResultRepository;
    private final AuditLogRepository auditLogs;
    private final JdbcTemplate jdbcTemplate;

    PatientService(
            PatientRepository patients,
            VisitRepository visits,
            PatientNumberGenerator patientNumbers,
            PatientMapper mapper,
            Clock clock,
            VitalsRepository vitalsRepository,
            ConsultationRepository consultationRepository,
            VitalsMapper vitalsMapper,
            ConsultationMapper consultationMapper,
            PrescriptionRepository prescriptionRepository,
            LabResultRepository labResultRepository,
            AuditLogRepository auditLogs,
            JdbcTemplate jdbcTemplate
    ) {
        this.patients = patients;
        this.visits = visits;
        this.patientNumbers = patientNumbers;
        this.mapper = mapper;
        this.clock = clock;
        this.vitalsRepository = vitalsRepository;
        this.consultationRepository = consultationRepository;
        this.vitalsMapper = vitalsMapper;
        this.consultationMapper = consultationMapper;
        this.prescriptionRepository = prescriptionRepository;
        this.labResultRepository = labResultRepository;
        this.auditLogs = auditLogs;
        this.jdbcTemplate = jdbcTemplate;
    }

    @Transactional
    PatientResponse create(CreatePatientRequest request) {
        PatientEntity patient = PatientEntity.create(request, patientNumbers.next());
        PatientEntity savedPatient = patients.save(patient);
        VisitEntity visit = visits.save(VisitEntity.openFor(savedPatient, request));
        return mapper.toResponse(savedPatient, visit);
    }

    @Transactional(readOnly = true)
    List<PatientResponse> list(String search, int limit) {
        List<PatientEntity> page = patients.search(normalizeSearch(search), PageRequest.of(0, limit));
        Map<UUID, VisitEntity> latestVisits = latestVisitsFor(page);
        return page.stream()
                .map(patient -> mapper.toResponse(patient, latestVisits.get(patient.id())))
                .toList();
    }

    @Transactional(readOnly = true)
    PatientResponse get(UUID id) {
        PatientEntity patient = patients.findById(id)
                .orElseThrow(() -> new BusinessException(
                        "PATIENT_NOT_FOUND",
                        "Patient introuvable.",
                        HttpStatus.NOT_FOUND
                ));
        VisitEntity latestVisit = latestVisitsFor(List.of(patient)).get(patient.id());
        return mapper.toResponse(patient, latestVisit);
    }

    @Transactional
    PatientResponse createVisit(UUID patientId, CreateVisitRequest request) {
        PatientEntity patient = findPatient(patientId);
        VisitEntity visit = visits.save(VisitEntity.openFor(patient, request));
        return mapper.toResponse(patient, visit);
    }

    @Transactional(readOnly = true)
    List<PatientResponse> todayQueue(int limit, VisitStatus status) {
        java.time.ZoneId zone = java.time.ZoneId.systemDefault();
        Instant start = LocalDate.now(clock.withZone(zone)).atStartOfDay(zone).toInstant();
        Instant end = start.plusSeconds(24 * 60 * 60);
        return visits.findTodayQueue(start, end, VisitStatus.RELEASED, status, PageRequest.of(0, limit))
                .stream()
                .map(visit -> mapper.toResponse(visit.patient(), visit))
                .toList();
    }

    private PatientEntity findPatient(UUID id) {
        return patients.findById(id)
                .orElseThrow(() -> new BusinessException(
                        "PATIENT_NOT_FOUND",
                        "Patient introuvable.",
                        HttpStatus.NOT_FOUND
                ));
    }

    private Map<UUID, VisitEntity> latestVisitsFor(Collection<PatientEntity> page) {
        List<UUID> patientIds = page.stream().map(PatientEntity::id).toList();
        Map<UUID, VisitEntity> latestVisits = new LinkedHashMap<>();
        if (patientIds.isEmpty()) {
            return latestVisits;
        }
        visits.findLatestCandidates(patientIds)
                .forEach(visit -> latestVisits.putIfAbsent(visit.patientId(), visit));
        return latestVisits;
    }

    private String normalizeSearch(String search) {
        if (search == null || search.isBlank()) {
            return null;
        }
        return "%" + search.trim().toLowerCase() + "%";
    }

    @Transactional(readOnly = true)
    public List<PatientTimelineItemResponse> getTimeline(UUID patientId) {
        PatientEntity patient = findPatient(patientId);
        List<VisitEntity> patientVisits = visits.findAllByPatientIdOrderByArrivalAtDesc(patient.id());

        return patientVisits.stream().map(visit -> {
            VitalsResponse vitalsResponse = vitalsRepository.findLatestCandidates(visit.id(), PageRequest.of(0, 1))
                    .stream()
                    .findFirst()
                    .map(vitalsMapper::toResponse)
                    .orElse(null);

            ConsultationResponse consultationResponse = consultationRepository.findByVisitId(visit.id())
                    .map(consultation -> {
                        boolean hasPrescription = prescriptionRepository.existsByConsultationId(consultation.id());
                        return consultationMapper.toResponse(
                                consultation,
                                visit.status(),
                                hasPrescription
                        );
                    })
                    .orElse(null);

            LabResultResponse labResultResponse = labResultRepository.findFirstByVisitIdOrderByCreatedAtDesc(visit.id())
                    .map(labResult -> new LabResultResponse(
                            labResult.id(),
                            labResult.resultNumber(),
                            labResult.dossierNumber(),
                            labResult.examType(),
                            labResult.results(),
                            labResult.observations(),
                            labResult.sampleDate(),
                            labResult.normalResults(),
                            labResult.status(),
                            labResult.createdAt()
                    ))
                    .orElse(null);

            return new PatientTimelineItemResponse(
                    visit.id(),
                    visit.reason(),
                    visit.targetService(),
                    visit.status(),
                    visit.priority(),
                    visit.arrivalAt(),
                    visit.closedAt(),
                    vitalsResponse,
                    consultationResponse,
                    labResultResponse
            );
        }).toList();
    }

    @Transactional
    public void logShare(ShareLogRequest request) {
        UUID userId = getCurrentUserId();
        String reason = String.format("Partagé via %s. Consentement du patient: %s.", 
                request.channel(), 
                request.consent() ? "Oui" : "Non");
        auditLogs.save(AuditLogEntity.log(
                userId,
                "SHARE_DOCUMENT",
                "PATIENT",
                request.entityType(),
                request.entityId(),
                reason
        ));
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
