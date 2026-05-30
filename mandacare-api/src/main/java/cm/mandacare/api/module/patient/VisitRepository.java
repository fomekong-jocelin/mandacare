package cm.mandacare.api.module.patient;

import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

interface VisitRepository extends JpaRepository<VisitEntity, UUID> {

    @Query("""
            select visit
            from VisitEntity visit
            where visit.patient.id in :patientIds
            order by visit.arrivalAt desc
            """)
    List<VisitEntity> findLatestCandidates(@Param("patientIds") Collection<UUID> patientIds);

    @Query("""
            select visit
            from VisitEntity visit
            where visit.patient.id = :patientId
            order by visit.arrivalAt desc
            """)
    List<VisitEntity> findAllByPatientIdOrderByArrivalAtDesc(@Param("patientId") UUID patientId);

    @Query("""
            select visit
            from VisitEntity visit
            join fetch visit.patient
            where visit.arrivalAt >= :start
              and visit.arrivalAt < :end
              and visit.status <> :closedStatus
              and (:status is null or visit.status = :status)
            order by visit.arrivalAt asc
            """)
    List<VisitEntity> findTodayQueue(
            @Param("start") Instant start,
            @Param("end") Instant end,
            @Param("closedStatus") VisitStatus closedStatus,
            @Param("status") VisitStatus status,
            Pageable pageable
    );
}
