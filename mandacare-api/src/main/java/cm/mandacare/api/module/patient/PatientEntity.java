package cm.mandacare.api.module.patient;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "patients")
class PatientEntity {

    @Id
    private UUID id;

    @Column(name = "patient_number", nullable = false, unique = true, length = 40)
    private String patientNumber;

    @Column(name = "first_name", nullable = false, length = 120)
    private String firstName;

    @Column(name = "last_name", nullable = false, length = 120)
    private String lastName;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private PatientSex sex;

    @Column(name = "birth_date")
    private LocalDate birthDate;

    @Column(name = "declared_age")
    private Integer declaredAge;

    @Column(nullable = false, length = 40)
    private String phone;

    @Column(length = 120)
    private String district;

    @Column(length = 120)
    private String city;

    @Column(name = "emergency_contact_name", length = 180)
    private String emergencyContactName;

    @Column(name = "emergency_contact_phone", length = 40)
    private String emergencyContactPhone;

    @Column(name = "digital_consent", nullable = false)
    private boolean digitalConsent;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected PatientEntity() {
    }

    static PatientEntity create(CreatePatientRequest request, String patientNumber) {
        PatientEntity patient = new PatientEntity();
        patient.id = UUID.randomUUID();
        patient.patientNumber = patientNumber;
        patient.firstName = request.firstName().trim();
        patient.lastName = request.lastName().trim();
        patient.sex = request.sex();
        patient.birthDate = request.birthDate();
        patient.declaredAge = request.declaredAge();
        patient.phone = request.phone().trim();
        patient.city = normalize(request.city());
        patient.district = normalize(request.district());
        patient.emergencyContactName = normalize(request.emergencyContactName());
        patient.emergencyContactPhone = normalize(request.emergencyContactPhone());
        patient.digitalConsent = false;
        return patient;
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

    String patientNumber() {
        return patientNumber;
    }

    String firstName() {
        return firstName;
    }

    String lastName() {
        return lastName;
    }

    String fullName() {
        return firstName + " " + lastName;
    }

    PatientSex sex() {
        return sex;
    }

    LocalDate birthDate() {
        return birthDate;
    }

    Integer declaredAge() {
        return declaredAge;
    }

    String phone() {
        return phone;
    }

    String city() {
        return city;
    }

    String district() {
        return district;
    }

    String emergencyContactName() {
        return emergencyContactName;
    }

    String emergencyContactPhone() {
        return emergencyContactPhone;
    }

    Instant createdAt() {
        return createdAt;
    }

    private static String normalize(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return value.trim();
    }
}
