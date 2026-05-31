package cm.mandacare.api.module.patient;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.HashMap;
import java.util.Map;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
class ReportService {

    private final JdbcTemplate jdbcTemplate;

    ReportService(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Transactional(readOnly = true)
    public ReportResponse getDailyReport() {
        Timestamp startOfDay = Timestamp.from(
                LocalDate.now().atStartOfDay(ZoneId.systemDefault()).toInstant()
        );

        // 1. Total patients d'aujourd'hui
        Long totalPatients = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM visits WHERE arrival_at >= ?",
                Long.class,
                startOfDay
        );
        if (totalPatients == null) totalPatients = 0L;

        // 2. Patients par statut
        Map<String, Long> patientsByStatus = new HashMap<>();
        jdbcTemplate.query(
                "SELECT status, COUNT(*) as count FROM visits WHERE arrival_at >= ? GROUP BY status",
                rs -> {
                    patientsByStatus.put(rs.getString("status"), rs.getLong("count"));
                },
                startOfDay
        );

        // 3. Recettes par mode de paiement
        Map<String, BigDecimal> revenueByPaymentMode = new HashMap<>();
        jdbcTemplate.query(
                "SELECT mode, SUM(amount) as sum FROM payments WHERE created_at >= ? AND status = 'VALIDATED' GROUP BY mode",
                rs -> {
                    revenueByPaymentMode.put(rs.getString("mode"), rs.getBigDecimal("sum"));
                },
                startOfDay
        );

        // 4. Recettes totales
        BigDecimal totalRevenue = jdbcTemplate.queryForObject(
                "SELECT SUM(amount) FROM payments WHERE created_at >= ? AND status = 'VALIDATED'",
                BigDecimal.class,
                startOfDay
        );
        if (totalRevenue == null) totalRevenue = BigDecimal.ZERO;

        // 5. Top examens prescrits
        Map<String, Long> topPrescribedExams = new HashMap<>();
        jdbcTemplate.query(
                "SELECT e.label, COUNT(*) as count " +
                "FROM exam_request_lines l " +
                "JOIN exams e ON l.exam_id = e.id " +
                "JOIN exam_requests r ON l.exam_request_id = r.id " +
                "WHERE r.created_at >= ? " +
                "GROUP BY e.label " +
                "ORDER BY count DESC LIMIT 5",
                rs -> {
                    topPrescribedExams.put(rs.getString("label"), rs.getLong("count"));
                },
                startOfDay
        );

        return new ReportResponse(
                totalPatients,
                patientsByStatus,
                revenueByPaymentMode,
                totalRevenue,
                topPrescribedExams
        );
    }
}
