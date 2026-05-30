package cm.mandacare.api.module.patient;

import java.util.List;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
class ExamService {

    private final ExamRepository examRepository;

    ExamService(ExamRepository examRepository) {
        this.examRepository = examRepository;
    }

    @Transactional(readOnly = true)
    public List<ExamResponse> listActiveExams() {
        return examRepository.findAll().stream()
                .filter(ExamEntity::isActive)
                .map(exam -> new ExamResponse(
                        exam.id(),
                        exam.code(),
                        exam.name(),
                        exam.category(),
                        exam.price(),
                        exam.isActive()
                ))
                .collect(Collectors.toList());
    }
}
