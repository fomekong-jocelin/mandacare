package cm.mandacare.api.module.patient;

import cm.mandacare.api.common.error.BusinessException;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
class TariffAdminService {

    private final ExamRepository examRepository;
    private final BenefitRepository benefitRepository;

    TariffAdminService(ExamRepository examRepository, BenefitRepository benefitRepository) {
        this.examRepository = examRepository;
        this.benefitRepository = benefitRepository;
    }

    // ─── Exams ───────────────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    List<ExamResponse> listAllExams() {
        return examRepository.findAll().stream()
                .map(e -> new ExamResponse(e.id(), e.code(), e.name(), e.category(), e.price(), e.isActive()))
                .toList();
    }

    @Transactional
    ExamResponse createExam(CreateTariffItemRequest request) {
        String code = request.code().trim().toUpperCase(Locale.ROOT);
        if (examRepository.findByCode(code).isPresent()) {
            throw new BusinessException(
                    "EXAM_CODE_ALREADY_EXISTS",
                    "Un examen avec ce code existe déjà.",
                    HttpStatus.CONFLICT
            );
        }
        ExamEntity exam = ExamEntity.create(UUID.randomUUID(), code, request.name().trim(),
                normalizeCategory(request.category()), request.price());
        return toExamResponse(examRepository.save(exam));
    }

    @Transactional
    ExamResponse updateExam(UUID id, UpdateTariffItemRequest request) {
        ExamEntity exam = examRepository.findById(id).orElseThrow(() ->
                new BusinessException("EXAM_NOT_FOUND", "Examen introuvable.", HttpStatus.NOT_FOUND));
        exam.update(request.name().trim(), normalizeCategory(request.category()), request.price(), request.active());
        return toExamResponse(exam);
    }

    // ─── Benefits ────────────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    List<BenefitResponse> listAllBenefits() {
        return benefitRepository.findAll().stream()
                .map(b -> new BenefitResponse(b.id(), b.code(), b.name(), b.category(), b.price(), b.isActive()))
                .toList();
    }

    @Transactional
    BenefitResponse createBenefit(CreateTariffItemRequest request) {
        String code = request.code().trim().toUpperCase(Locale.ROOT);
        if (benefitRepository.findByCode(code).isPresent()) {
            throw new BusinessException(
                    "BENEFIT_CODE_ALREADY_EXISTS",
                    "Un acte avec ce code existe déjà.",
                    HttpStatus.CONFLICT
            );
        }
        BenefitEntity benefit = BenefitEntity.create(UUID.randomUUID(), code, request.name().trim(),
                normalizeCategory(request.category()), request.price());
        return toBenefitResponse(benefitRepository.save(benefit));
    }

    @Transactional
    BenefitResponse updateBenefit(UUID id, UpdateTariffItemRequest request) {
        BenefitEntity benefit = benefitRepository.findById(id).orElseThrow(() ->
                new BusinessException("BENEFIT_NOT_FOUND", "Acte introuvable.", HttpStatus.NOT_FOUND));
        benefit.update(request.name().trim(), normalizeCategory(request.category()), request.price(), request.active());
        return toBenefitResponse(benefit);
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────────

    private ExamResponse toExamResponse(ExamEntity e) {
        return new ExamResponse(e.id(), e.code(), e.name(), e.category(), e.price(), e.isActive());
    }

    private BenefitResponse toBenefitResponse(BenefitEntity b) {
        return new BenefitResponse(b.id(), b.code(), b.name(), b.category(), b.price(), b.isActive());
    }

    private String normalizeCategory(String category) {
        if (category == null || category.trim().isEmpty()) {
            return null;
        }
        return category.trim().toUpperCase(Locale.ROOT);
    }
}
