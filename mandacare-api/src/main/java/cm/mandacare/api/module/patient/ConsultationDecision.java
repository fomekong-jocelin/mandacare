package cm.mandacare.api.module.patient;

public enum ConsultationDecision {
    KEEP_IN_CONSULTATION(VisitStatus.IN_CONSULTATION),
    SEND_TO_LAB(VisitStatus.CASH_DESK),
    RELEASE_PATIENT(VisitStatus.CASH_DESK);

    private final VisitStatus visitStatus;

    ConsultationDecision(VisitStatus visitStatus) {
        this.visitStatus = visitStatus;
    }

    VisitStatus visitStatus() {
        return visitStatus;
    }

    VisitStatus statusAfterCashDesk() {
        return switch (this) {
            case SEND_TO_LAB -> VisitStatus.LAB;
            case RELEASE_PATIENT -> VisitStatus.RELEASED;
            case KEEP_IN_CONSULTATION -> VisitStatus.IN_CONSULTATION;
        };
    }
}
