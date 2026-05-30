package cm.mandacare.api.module.patient;

import java.util.List;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/exams")
class ExamController {

    private final ExamService service;

    ExamController(ExamService service) {
        this.service = service;
    }

    @GetMapping
    List<ExamResponse> list() {
        return service.listActiveExams();
    }
}
