package cm.mandacare.api.module.dashboard;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

@Service
class DashboardService {

    private final JdbcTemplate jdbc;
    private final Clock clock;

    DashboardService(JdbcTemplate jdbc, Clock clock) {
        this.jdbc = jdbc;
        this.clock = clock;
    }

    DashboardTodayResponse today() {
        java.time.ZoneId zone = java.time.ZoneId.systemDefault();
        Instant start = LocalDate.now(clock.withZone(zone)).atStartOfDay(zone).toInstant();
        Instant end = start.plusSeconds(24 * 60 * 60);

        return new DashboardTodayResponse(
                count("""
                        select count(*)
                        from visits
                        where arrival_at >= ? and arrival_at < ?
                        """, start, end),
                count("""
                        select count(*)
                        from visits
                        where status <> 'RELEASED'
                        """),
                count("""
                        select count(*)
                        from visits
                        where status = 'WAITING'
                        """),
                count("""
                        select count(*)
                        from visits
                        where status = 'IN_CONSULTATION'
                        """),
                count("""
                        select count(*)
                        from visits
                        where status = 'CASH_DESK'
                        """),
                count("""
                        select count(*)
                        from visits
                        where status = 'LAB'
                        """),
                count("""
                        select count(*)
                        from consultations
                        where created_at >= ? and created_at < ?
                        """, start, end),
                count("""
                        select count(*)
                        from visits
                        where status = 'LAB'
                        """),
                count("""
                        select count(*)
                        from visit_lab_results
                        where validated_at >= ? and validated_at < ?
                        """, start, end),
                sum("""
                        select coalesce(sum(paid_amount), 0)
                        from invoices
                        where created_at >= ? and created_at < ?
                        """, start, end),
                count("""
                        select count(*)
                        from invoices
                        where created_at >= ? and created_at < ?
                          and remaining_amount > 0
                        """, start, end)
        );
    }

    private int count(String sql, Instant start, Instant end) {
        Integer value = jdbc.queryForObject(
                sql,
                Integer.class,
                Timestamp.from(start),
                Timestamp.from(end)
        );
        return value == null ? 0 : value;
    }

    private int count(String sql) {
        Integer value = jdbc.queryForObject(sql, Integer.class);
        return value == null ? 0 : value;
    }

    private BigDecimal sum(String sql, Instant start, Instant end) {
        BigDecimal value = jdbc.queryForObject(
                sql,
                BigDecimal.class,
                Timestamp.from(start),
                Timestamp.from(end)
        );
        return value == null ? BigDecimal.ZERO : value;
    }
}
