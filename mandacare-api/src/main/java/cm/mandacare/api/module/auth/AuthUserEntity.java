package cm.mandacare.api.module.auth;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "auth_users")
class AuthUserEntity {

    @Id
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "role_id", nullable = false)
    private RoleEntity role;

    @Column(name = "first_name", nullable = false, length = 120)
    private String firstName;

    @Column(name = "last_name", nullable = false, length = 120)
    private String lastName;

    @Column(length = 40)
    private String phone;

    @Column(length = 180)
    private String email;

    @Column(nullable = false, unique = true, length = 80)
    private String username;

    @Column(name = "password_hash", nullable = false)
    private String passwordHash;

    @Column(nullable = false, length = 30)
    private String status;

    @Column(name = "last_login_at")
    private Instant lastLoginAt;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected AuthUserEntity() {
    }

    static AuthUserEntity staff(
            RoleEntity role,
            String firstName,
            String lastName,
            String phone,
            String email,
            String username,
            String passwordHash
    ) {
        AuthUserEntity user = new AuthUserEntity();
        user.id = UUID.randomUUID();
        user.role = role;
        user.firstName = firstName;
        user.lastName = lastName;
        user.phone = phone;
        user.email = email;
        user.username = username;
        user.passwordHash = passwordHash;
        user.status = "ACTIVE";
        return user;
    }

    static AuthUserEntity admin(RoleEntity role, AuthProperties.DefaultAdmin admin, String passwordHash) {
        AuthUserEntity user = new AuthUserEntity();
        user.id = UUID.randomUUID();
        user.role = role;
        user.firstName = admin.firstName();
        user.lastName = admin.lastName();
        user.username = admin.username();
        user.passwordHash = passwordHash;
        user.status = "ACTIVE";
        return user;
    }

    @PrePersist
    void onCreate() {
        Instant now = Instant.now();
        createdAt = now;
        updatedAt = now;
    }

    @PreUpdate
    void onUpdate() {
        updatedAt = Instant.now();
    }

    UUID id() {
        return id;
    }

    String username() {
        return username;
    }

    RoleEntity role() {
        return role;
    }

    String firstName() {
        return firstName;
    }

    String lastName() {
        return lastName;
    }

    String phone() {
        return phone;
    }

    String email() {
        return email;
    }

    String status() {
        return status;
    }

    Instant lastLoginAt() {
        return lastLoginAt;
    }

    Instant createdAt() {
        return createdAt;
    }

    Instant updatedAt() {
        return updatedAt;
    }

    String passwordHash() {
        return passwordHash;
    }

    String displayName() {
        return firstName + " " + lastName;
    }

    boolean active() {
        return "ACTIVE".equals(status);
    }

    void updateProfile(
            RoleEntity role,
            String firstName,
            String lastName,
            String phone,
            String email,
            String username,
            String status
    ) {
        this.role = role;
        this.firstName = firstName;
        this.lastName = lastName;
        this.phone = phone;
        this.email = email;
        this.username = username;
        this.status = status;
    }

    void changePassword(String passwordHash) {
        this.passwordHash = passwordHash;
    }

    void markLoggedIn() {
        lastLoginAt = Instant.now();
    }
}
