package cm.mandacare.api.module.patient;

import java.security.SecureRandom;
import java.time.Clock;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import org.springframework.stereotype.Component;

@Component
class ExamRequestNumberGenerator {

    private static final DateTimeFormatter DATE_FORMAT = DateTimeFormatter.BASIC_ISO_DATE;
    private final SecureRandom random = new SecureRandom();
    private final Clock clock;
    private final ExamRequestRepository repository;

    ExamRequestNumberGenerator(Clock clock, ExamRequestRepository repository) {
        this.clock = clock;
        this.repository = repository;
    }

    String next() {
        for (int attempt = 0; attempt < 5; attempt++) {
            String requestNumber = candidate();
            if (repository.findByRequestNumber(requestNumber).isEmpty()) {
                return requestNumber;
            }
        }
        throw new IllegalStateException("Impossible de générer un numéro de demande d'examen unique.");
    }

    private String candidate() {
        String date = LocalDate.now(clock).format(DATE_FORMAT);
        int suffix = random.nextInt(1_000_000);
        return "EXM-%s-%06d".formatted(date, suffix);
    }
}
