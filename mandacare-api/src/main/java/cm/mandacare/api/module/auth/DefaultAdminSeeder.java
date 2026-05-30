package cm.mandacare.api.module.auth;

import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Component
class DefaultAdminSeeder implements ApplicationRunner {

    private static final String ADMIN_ROLE_CODE = "ADMIN";

    private final AuthProperties properties;
    private final RoleRepository roles;
    private final AuthUserRepository users;
    private final PasswordEncoder passwordEncoder;

    DefaultAdminSeeder(
            AuthProperties properties,
            RoleRepository roles,
            AuthUserRepository users,
            PasswordEncoder passwordEncoder
    ) {
        this.properties = properties;
        this.roles = roles;
        this.users = users;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        seedDefaultRoles();

        AuthProperties.DefaultAdmin admin = properties.defaultAdmin();
        if (!admin.enabled() || users.existsByUsernameIgnoreCase(admin.username())) {
            return;
        }

        RoleEntity adminRole = roles.findByCode(ADMIN_ROLE_CODE).orElseGet(() -> roles.save(RoleEntity.admin()));
        String encodedPassword = passwordEncoder.encode(admin.password());
        users.save(AuthUserEntity.admin(adminRole, admin, encodedPassword));
    }

    private void seedDefaultRoles() {
        seedRole(
                ADMIN_ROLE_CODE,
                "Administrateur",
                "Accès complet aux dossiers, aux opérations et à la configuration."
        );
        seedRole(
                "MEDECIN",
                "Médecin",
                "Consultations, diagnostics, prescriptions et décisions de parcours patient."
        );
        seedRole(
                "INFIRMIER",
                "Infirmier",
                "Accueil clinique, constantes, soins et suivi des patients du jour."
        );
        seedRole(
                "CAISSIER",
                "Caissier",
                "Facturation, encaissement et reçus des dossiers orientés en caisse."
        );
        seedRole(
                "LABORATOIRE",
                "Laboratoire",
                "Prélèvements, saisie et validation des résultats d'examens."
        );
        seedRole(
                "ACCUEIL",
                "Accueil",
                "Création des dossiers, arrivée des patients et orientation initiale."
        );
        seedRole(
                "AUTRE",
                "Autre profil",
                "Profil opérationnel à préciser selon l'organisation de la structure."
        );
    }

    private void seedRole(String code, String label, String description) {
        roles.findByCode(code).orElseGet(() -> roles.save(RoleEntity.of(code, label, description)));
    }
}
