package cm.mandacare.api.module.dashboard;

import java.math.BigDecimal;
import org.springframework.stereotype.Service;

@Service
class DashboardService {

    DashboardTodayResponse today() {
        return new DashboardTodayResponse(0, 0, 0, 0, BigDecimal.ZERO, 0);
    }
}

