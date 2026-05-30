package cm.mandacare.api.module.auth;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.util.UUID;

@Entity
@Table(name = "roles")
class RoleEntity {

    @Id
    private UUID id;

    @Column(nullable = false, unique = true, length = 40)
    private String code;

    @Column(nullable = false, length = 120)
    private String label;

    private String description;

    protected RoleEntity() {
    }

    static RoleEntity admin() {
        return of(
                "ADMIN",
                "Administrateur",
                "Accès complet aux dossiers, aux opérations et à la configuration."
        );
    }

    static RoleEntity of(String code, String label, String description) {
        RoleEntity role = new RoleEntity();
        role.id = UUID.randomUUID();
        role.code = code;
        role.label = label;
        role.description = description;
        return role;
    }

    String code() {
        return code;
    }

    String label() {
        return label;
    }

    String description() {
        return description;
    }
}
