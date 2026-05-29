package cm.mandacare.api.module.patient;

import java.util.List;
import java.util.UUID;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

interface VitalsRepository extends JpaRepository<VitalsEntity, UUID> {

    @Query("""
            select vitals
            from VitalsEntity vitals
            where vitals.visit.id = :visitId
            order by vitals.createdAt desc
            """)
    List<VitalsEntity> findLatestCandidates(@Param("visitId") UUID visitId, Pageable pageable);
}
