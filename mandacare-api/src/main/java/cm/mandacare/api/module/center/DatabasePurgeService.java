package cm.mandacare.api.module.center;

import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
class DatabasePurgeService {

    private final JdbcTemplate jdbcTemplate;

    DatabasePurgeService(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Transactional
    public void purge() {
        UUID userId = getCurrentUserId();

        // 1. Delete patient and transactional data in dependency order to avoid foreign key violations
        jdbcTemplate.execute("DELETE FROM prescription_items");
        jdbcTemplate.execute("DELETE FROM prescriptions");
        jdbcTemplate.execute("DELETE FROM vitals");
        jdbcTemplate.execute("DELETE FROM exam_request_lines");
        jdbcTemplate.execute("DELETE FROM exam_requests");
        jdbcTemplate.execute("DELETE FROM visit_lab_results");
        jdbcTemplate.execute("DELETE FROM lab_results");
        jdbcTemplate.execute("DELETE FROM invoice_items");
        jdbcTemplate.execute("DELETE FROM payments");
        jdbcTemplate.execute("DELETE FROM invoices");
        jdbcTemplate.execute("DELETE FROM documents");
        jdbcTemplate.execute("DELETE FROM support_tickets");
        jdbcTemplate.execute("DELETE FROM stock_movements");
        jdbcTemplate.execute("DELETE FROM consultations");
        jdbcTemplate.execute("DELETE FROM visits");
        jdbcTemplate.execute("DELETE FROM patients");
        jdbcTemplate.execute("DELETE FROM audit_logs");

        // 2. Reset pharmacy item stock quantities to their initial values
        jdbcTemplate.execute(
            """
            UPDATE pharmacy_items SET stock_quantity = CASE 
                WHEN code = 'PARACET500' THEN 50
                WHEN code = 'AMOXICILLIN' THEN 3
                WHEN code = 'IBUPROFEN' THEN 20
                ELSE 0
            END
            """
        );

        // 3. Write a fresh audit log entry for the purge action
        jdbcTemplate.update(
            """
            INSERT INTO audit_logs (id, user_id, action, module, entity_type, entity_id, reason, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
            """,
            UUID.randomUUID(),
            userId,
            "PURGE_DATABASE",
            "DATABASE",
            null,
            null,
            "Purge complète des données de l'application (patients, consultations, factures, visites, etc.) effectuée par l'administrateur."
        );
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
