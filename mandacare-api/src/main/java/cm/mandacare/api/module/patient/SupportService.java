package cm.mandacare.api.module.patient;

import cm.mandacare.api.common.error.BusinessException;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
class SupportService {

    private final SupportTicketRepository tickets;
    private final JdbcTemplate jdbcTemplate;

    SupportService(SupportTicketRepository tickets, JdbcTemplate jdbcTemplate) {
        this.tickets = tickets;
        this.jdbcTemplate = jdbcTemplate;
    }

    @Transactional
    public SupportTicketResponse create(CreateSupportTicketRequest request) {
        UUID userId = getCurrentUserId();
        if (userId == null) {
            throw new BusinessException(
                    "UNAUTHORIZED",
                    "Vous devez être connecté pour soumettre un ticket.",
                    HttpStatus.UNAUTHORIZED
            );
        }
        SupportTicketEntity ticket = SupportTicketEntity.create(
                request.subject(),
                request.description(),
                request.category(),
                request.priority(),
                userId
        );
        return mapToResponse(tickets.save(ticket));
    }

    @Transactional(readOnly = true)
    public List<SupportTicketResponse> listMyTickets() {
        UUID userId = getCurrentUserId();
        if (userId == null) {
            return List.of();
        }
        return tickets.findAllByUserIdOrderByCreatedAtDesc(userId).stream()
                .map(this::mapToResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<SupportTicketResponse> listAll() {
        return tickets.findAllByOrderByCreatedAtDesc().stream()
                .map(this::mapToResponse)
                .toList();
    }

    @Transactional
    public SupportTicketResponse resolve(UUID id) {
        SupportTicketEntity ticket = tickets.findById(id)
                .orElseThrow(() -> new BusinessException(
                        "TICKET_NOT_FOUND",
                        "Ticket de support introuvable.",
                        HttpStatus.NOT_FOUND
                ));
        ticket.resolve();
        return mapToResponse(tickets.save(ticket));
    }

    private SupportTicketResponse mapToResponse(SupportTicketEntity ticket) {
        return new SupportTicketResponse(
                ticket.id(),
                ticket.subject(),
                ticket.description(),
                ticket.category(),
                ticket.priority(),
                ticket.status(),
                ticket.createdAt(),
                ticket.userId()
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
