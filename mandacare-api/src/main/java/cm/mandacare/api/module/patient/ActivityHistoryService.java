package cm.mandacare.api.module.patient;

import java.sql.Timestamp;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
class ActivityHistoryService {

    private final JdbcTemplate jdbc;
    private final Clock clock;

    ActivityHistoryService(JdbcTemplate jdbc, Clock clock) {
        this.jdbc = jdbc;
        this.clock = clock;
    }

    @Transactional(readOnly = true)
    List<ConsultationHistoryItemResponse> consultations(LocalDate from, LocalDate to, int limit) {
        DateWindow window = DateWindow.of(from, to, clock);
        return jdbc.query("""
                select c.id, c.visit_id, c.patient_id, p.patient_number,
                       concat(p.first_name, ' ', p.last_name) as patient_name,
                       c.reason, coalesce(c.final_diagnosis, c.provisional_diagnosis, '') as diagnosis,
                       c.status, c.decision, c.created_at, c.validated_at,
                       exists (
                           select 1
                           from prescriptions pr
                           where pr.consultation_id = c.id
                       ) as has_prescription
                from consultations c
                join patients p on p.id = c.patient_id
                where c.created_at >= ? and c.created_at < ?
                order by c.created_at desc
                limit ?
                """,
                (rs, rowNum) -> new ConsultationHistoryItemResponse(
                        rs.getObject("id", java.util.UUID.class),
                        rs.getObject("visit_id", java.util.UUID.class),
                        rs.getObject("patient_id", java.util.UUID.class),
                        rs.getString("patient_number"),
                        rs.getString("patient_name"),
                        rs.getString("reason"),
                        rs.getString("diagnosis"),
                        ConsultationStatus.valueOf(rs.getString("status")),
                        ConsultationDecision.valueOf(rs.getString("decision")),
                        rs.getBoolean("has_prescription"),
                        rs.getTimestamp("created_at").toInstant(),
                        timestampToInstant(rs.getTimestamp("validated_at"))
                ),
                Timestamp.from(window.start()),
                Timestamp.from(window.end()),
                limit
        );
    }

    @Transactional(readOnly = true)
    List<CashDeskHistoryItemResponse> cashDesk(LocalDate from, LocalDate to, int limit) {
        DateWindow window = DateWindow.of(from, to, clock);
        return jdbc.query("""
                select i.id, i.visit_id, i.patient_id, i.invoice_number,
                       concat(p.first_name, ' ', p.last_name) as patient_name,
                       i.net_amount, i.paid_amount, i.remaining_amount, i.status, i.created_at
                from invoices i
                join patients p on p.id = i.patient_id
                where i.created_at >= ? and i.created_at < ?
                order by i.created_at desc
                limit ?
                """,
                (rs, rowNum) -> new CashDeskHistoryItemResponse(
                        rs.getObject("id", java.util.UUID.class),
                        rs.getObject("visit_id", java.util.UUID.class),
                        rs.getObject("patient_id", java.util.UUID.class),
                        rs.getString("invoice_number"),
                        rs.getString("patient_name"),
                        rs.getBigDecimal("net_amount"),
                        rs.getBigDecimal("paid_amount"),
                        rs.getBigDecimal("remaining_amount"),
                        rs.getString("status"),
                        rs.getTimestamp("created_at").toInstant()
                ),
                Timestamp.from(window.start()),
                Timestamp.from(window.end()),
                limit
        );
    }

    private static Instant timestampToInstant(Timestamp timestamp) {
        return timestamp == null ? null : timestamp.toInstant();
    }

    private record DateWindow(Instant start, Instant end) {
        static DateWindow of(LocalDate from, LocalDate to, Clock clock) {
            ZoneId zone = ZoneId.systemDefault();
            LocalDate endDate = to == null ? LocalDate.now(clock.withZone(zone)).plusDays(1) : to.plusDays(1);
            LocalDate startDate = from == null ? endDate.minusDays(30) : from;
            return new DateWindow(
                    startDate.atStartOfDay(zone).toInstant(),
                    endDate.atStartOfDay(zone).toInstant()
            );
        }
    }
}
