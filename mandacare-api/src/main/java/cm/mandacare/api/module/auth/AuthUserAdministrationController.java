package cm.mandacare.api.module.auth;

import jakarta.validation.Valid;
import java.net.URI;
import java.util.List;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

@RestController
@RequestMapping("/api/v1/auth")
@PreAuthorize("hasRole('ADMIN')")
class AuthUserAdministrationController {

    private final AuthUserAdministrationService service;

    AuthUserAdministrationController(AuthUserAdministrationService service) {
        this.service = service;
    }

    @GetMapping("/roles")
    List<RoleProfileResponse> listRoles() {
        return service.listRoles();
    }

    @GetMapping("/users")
    List<AuthUserResponse> listUsers() {
        return service.listUsers();
    }

    @PostMapping("/users")
    ResponseEntity<AuthUserResponse> create(@Valid @RequestBody CreateAuthUserRequest request) {
        AuthUserResponse response = service.create(request);
        URI location = ServletUriComponentsBuilder
                .fromCurrentRequest()
                .path("/{id}")
                .buildAndExpand(response.id())
                .toUri();
        return ResponseEntity.created(location).body(response);
    }

    @PatchMapping("/users/{id}")
    AuthUserResponse update(
            @PathVariable UUID id,
            @Valid @RequestBody UpdateAuthUserRequest request
    ) {
        return service.update(id, request);
    }
}
