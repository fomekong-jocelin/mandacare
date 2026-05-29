package cm.mandacare.api.module.patient;

import java.util.UUID;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

interface ConsultationRepository extends JpaRepository<ConsultationEntity, UUID> {

    @Query("""
            select c
            from ConsultationEntity c
            where c.visit.id = :visitId
            """)
    Optional<ConsultationEntity> findByVisitId(@Param("visitId") UUID visitId);
}
