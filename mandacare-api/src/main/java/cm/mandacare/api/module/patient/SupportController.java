package cm.mandacare.api.module.patient;

import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Validated
@RestController
@RequestMapping("/api/v1/support")
@PreAuthorize("isAuthenticated()")
class SupportController {

    private final SupportService service;

    SupportController(SupportService service) {
        this.service = service;
    }

    @PostMapping("/tickets")
    SupportTicketResponse create(@Valid @RequestBody CreateSupportTicketRequest request) {
        return service.create(request);
    }

    @GetMapping("/tickets/mine")
    List<SupportTicketResponse> listMyTickets() {
        return service.listMyTickets();
    }

    @GetMapping("/tickets")
    @PreAuthorize("hasRole('ADMIN')")
    List<SupportTicketResponse> listAll() {
        return service.listAll();
    }

    @PutMapping("/tickets/{id}/resolve")
    @PreAuthorize("hasRole('ADMIN')")
    SupportTicketResponse resolve(@PathVariable UUID id) {
        return service.resolve(id);
    }
}
