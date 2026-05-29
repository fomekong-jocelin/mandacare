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
        RoleEntity role = new RoleEntity();
        role.id = UUID.randomUUID();
        role.code = "ADMIN";
        role.label = "Administrateur";
        role.description = "Accès administrateur local";
        return role;
    }
}
