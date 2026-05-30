package cm.mandacare.api.module.auth;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

interface AuthUserRepository extends JpaRepository<AuthUserEntity, UUID> {

    @EntityGraph(attributePaths = "role")
    Optional<AuthUserEntity> findByUsernameIgnoreCase(String username);

    @EntityGraph(attributePaths = "role")
    Optional<AuthUserEntity> findWithRoleById(UUID id);

    @EntityGraph(attributePaths = "role")
    java.util.List<AuthUserEntity> findAllByOrderByCreatedAtDesc();

    boolean existsByUsernameIgnoreCase(String username);

    boolean existsByUsernameIgnoreCaseAndIdNot(String username, UUID id);
}
