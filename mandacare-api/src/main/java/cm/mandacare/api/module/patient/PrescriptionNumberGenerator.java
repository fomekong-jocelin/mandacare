package cm.mandacare.api.module.patient;

import java.security.SecureRandom;
import java.time.Clock;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import org.springframework.stereotype.Component;

@Component
class PrescriptionNumberGenerator {

    private static final DateTimeFormatter DATE_FORMAT = DateTimeFormatter.BASIC_ISO_DATE;
    private final SecureRandom random = new SecureRandom();
    private final Clock clock;
    private final PrescriptionRepository repository;

    PrescriptionNumberGenerator(Clock clock, PrescriptionRepository repository) {
        this.clock = clock;
        this.repository = repository;
    }

    String next() {
        for (int attempt = 0; attempt < 5; attempt++) {
            String prescriptionNumber = candidate();
            if (!repository.existsByPrescriptionNumber(prescriptionNumber)) {
                return prescriptionNumber;
            }
        }
        throw new IllegalStateException("Impossible de générer un numéro d'ordonnance unique.");
    }

    private String candidate() {
        String date = LocalDate.now(clock).format(DATE_FORMAT);
        int suffix = random.nextInt(1_000_000);
        return "ORD-%s-%06d".formatted(date, suffix);
    }
}
