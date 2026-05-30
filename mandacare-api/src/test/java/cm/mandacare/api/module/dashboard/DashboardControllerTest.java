package cm.mandacare.api.module.dashboard;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import java.math.BigDecimal;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

@ActiveProfiles("test")
@SpringBootTest
@AutoConfigureMockMvc
class DashboardControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void returnsRealDailyActivityAndRevenue() throws Exception {
        String before = dashboardBody();
        int initialPatients = intValue(before, "$.patientsToday");
        int initialConsultations = intValue(before, "$.consultationsToday");
        BigDecimal initialRevenue = decimalValue(before, "$.dailyRevenue");

        String patientBody = mockMvc.perform(post("/api/v1/patients")
                        .with(user("doctor").roles("ADMIN", "MEDECIN"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(validPatientJson()))
                .andExpect(status().isCreated())
                .andReturn()
                .getResponse()
                .getContentAsString();
        String visitId = JsonPath.read(patientBody, "$.latestVisit.id");

        mockMvc.perform(post("/api/v1/visits/{id}/consultations", visitId)
                        .with(user("doctor").roles("ADMIN", "MEDECIN"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "symptoms": "Contrôle post traitement",
                                  "clinicalExam": "Patient stable",
                                  "diagnosis": "Sortie possible",
                                  "advice": "Surveillance à domicile",
                                  "decision": "RELEASE_PATIENT"
                                }
                                """))
                .andExpect(status().isCreated());

        mockMvc.perform(patch("/api/v1/visits/{id}/cash-desk/complete", visitId)
                        .with(user("cashier").roles("ADMIN", "CAISSIER"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "amount": 12500,
                                  "mode": "CASH",
                                  "reference": "RECU-DASH"
                                }
                                """))
                .andExpect(status().isOk());

        String after = dashboardBody();
        assertEquals(initialPatients + 1, intValue(after, "$.patientsToday"));
        assertEquals(initialConsultations + 1, intValue(after, "$.consultationsToday"));
        assertEquals(
                0,
                initialRevenue
                        .add(new BigDecimal("12500"))
                        .compareTo(decimalValue(after, "$.dailyRevenue"))
        );
    }

    private String dashboardBody() throws Exception {
        return mockMvc.perform(get("/api/v1/dashboard/today")
                        .with(user("manager").roles("ADMIN")))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString();
    }

    private int intValue(String json, String path) {
        Number number = JsonPath.read(json, path);
        return number.intValue();
    }

    private BigDecimal decimalValue(String json, String path) {
        Number number = JsonPath.read(json, path);
        return new BigDecimal(number.toString());
    }

    private String validPatientJson() {
        return """
                {
                  "firstName": "Dashboard",
                  "lastName": "Patient",
                  "sex": "FEMALE",
                  "declaredAge": 34,
                  "phone": "+221 70 900 00 01",
                  "city": "Dakar",
                  "district": "Plateau",
                  "emergencyContactName": "Contact Dashboard",
                  "emergencyContactPhone": "+221 77 111 22 33",
                  "arrivalReason": "Contrôle",
                  "priority": "STANDARD",
                  "targetService": "CONSULTATION"
                }
                """;
    }
}
