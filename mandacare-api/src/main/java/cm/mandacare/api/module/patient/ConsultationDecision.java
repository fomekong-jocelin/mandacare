package cm.mandacare.api.module.patient;

public enum ConsultationDecision {
    KEEP_IN_CONSULTATION(VisitStatus.IN_CONSULTATION),
    SEND_TO_LAB(VisitStatus.LAB),
    RELEASE_PATIENT(VisitStatus.RELEASED);

    private final VisitStatus visitStatus;

    ConsultationDecision(VisitStatus visitStatus) {
        this.visitStatus = visitStatus;
    }

    VisitStatus visitStatus() {
        return visitStatus;
    }
}
