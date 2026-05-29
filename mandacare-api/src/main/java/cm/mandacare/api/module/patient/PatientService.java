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

    PatientService(
            PatientRepository patients,
            VisitRepository visits,
            PatientNumberGenerator patientNumbers,
            PatientMapper mapper,
            Clock clock,
            VitalsRepository vitalsRepository,
            ConsultationRepository consultationRepository,
            VitalsMapper vitalsMapper,
            ConsultationMapper consultationMapper
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
    List<PatientResponse> todayQueue(int limit) {
        Instant start = LocalDate.now(clock).atStartOfDay(clock.getZone()).toInstant();
        Instant end = start.plusSeconds(24 * 60 * 60);
        return visits.findTodayQueue(start, end, VisitStatus.RELEASED, PageRequest.of(0, limit))
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
                    .map(consultation -> consultationMapper.toResponse(
                            consultation,
                            getDecisionFromStatus(visit.status()),
                            visit.status()
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
                    consultationResponse
            );
        }).toList();
    }

    private ConsultationDecision getDecisionFromStatus(VisitStatus status) {
        return switch (status) {
            case LAB -> ConsultationDecision.SEND_TO_LAB;
            case RELEASED -> ConsultationDecision.RELEASE_PATIENT;
            default -> ConsultationDecision.KEEP_IN_CONSULTATION;
        };
    }
}
