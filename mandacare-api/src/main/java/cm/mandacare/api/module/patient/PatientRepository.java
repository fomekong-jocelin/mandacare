package cm.mandacare.api.module.patient;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

interface PatientRepository extends JpaRepository<PatientEntity, UUID> {

    boolean existsByPatientNumber(String patientNumber);

    @Query("""
            select patient
            from PatientEntity patient
            where :search is null
               or lower(patient.firstName) like :search
               or lower(patient.lastName) like :search
               or lower(concat(patient.firstName, ' ', patient.lastName)) like :search
               or lower(concat(patient.lastName, ' ', patient.firstName)) like :search
               or lower(patient.phone) like :search
               or lower(patient.patientNumber) like :search
            order by patient.createdAt desc
            """)
    List<PatientEntity> search(@Param("search") String search, Pageable pageable);

    Optional<PatientEntity> findById(UUID id);
}
