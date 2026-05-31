package cm.mandacare.api.module.patient;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import java.math.BigDecimal;
import java.util.Map;
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
class ReportControllerTest {

    private static final String NFS_EXAM_ID = "30000000-0000-0000-0000-000000000007";

    @Autowired
    private MockMvc mockMvc;

    @Test
    void returnsDailyReportWithRevenueAndPrescribedExamNames() throws Exception {
        String before = reportBody();
        long initialPatients = longValue(before, "$.totalPatientsToday");
        BigDecimal initialRevenue = decimalValue(before, "$.totalRevenue");
        long initialCashRevenue = longFromMap(before, "$.revenueByPaymentMode", "CASH");
        long initialLabVisits = longFromMap(before, "$.patientsByStatus", "LAB");
        long initialNfsCount = longFromMap(before, "$.topPrescribedExams", "NFS");

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
                                  "symptoms": "Fièvre et fatigue",
                                  "clinicalExam": "Patient stable",
                                  "diagnosis": "Bilan biologique demandé",
                                  "advice": "Faire les examens prescrits",
                                  "decision": "SEND_TO_LAB",
                                  "prescribedExams": ["%s"]
                                }
                                """.formatted(NFS_EXAM_ID)))
                .andExpect(status().isCreated());

        mockMvc.perform(patch("/api/v1/visits/{id}/cash-desk/complete", visitId)
                        .with(user("cashier").roles("ADMIN", "CAISSIER"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "amount": 9000,
                                  "mode": "CASH",
                                  "reference": "RECU-REPORT"
                                }
                                """))
                .andExpect(status().isOk());

        String after = reportBody();
        assertEquals(initialPatients + 1, longValue(after, "$.totalPatientsToday"));
        assertEquals(initialLabVisits + 1, longFromMap(after, "$.patientsByStatus", "LAB"));
        assertEquals(initialCashRevenue + 9000, longFromMap(after, "$.revenueByPaymentMode", "CASH"));
        assertEquals(initialNfsCount + 1, longFromMap(after, "$.topPrescribedExams", "NFS"));
        assertEquals(
                0,
                initialRevenue
                        .add(new BigDecimal("9000"))
                        .compareTo(decimalValue(after, "$.totalRevenue"))
        );
    }

    private String reportBody() throws Exception {
        return mockMvc.perform(get("/api/v1/reports/daily")
                        .with(user("manager").roles("ADMIN")))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString();
    }

    private long longValue(String json, String path) {
        Number number = JsonPath.read(json, path);
        return number.longValue();
    }

    private BigDecimal decimalValue(String json, String path) {
        Number number = JsonPath.read(json, path);
        return new BigDecimal(number.toString());
    }

    private long longFromMap(String json, String path, String key) {
        Map<String, Object> values = JsonPath.read(json, path);
        Object value = values.get(key);
        if (value instanceof Number number) {
            return number.longValue();
        }
        return 0;
    }

    private String validPatientJson() {
        return """
                {
                  "firstName": "Report",
                  "lastName": "Patient",
                  "sex": "FEMALE",
                  "declaredAge": 29,
                  "phone": "+221 70 900 00 02",
                  "city": "Dakar",
                  "district": "Plateau",
                  "emergencyContactName": "Contact Report",
                  "emergencyContactPhone": "+221 77 111 22 34",
                  "arrivalReason": "Fièvre",
                  "priority": "STANDARD",
                  "targetService": "CONSULTATION"
                }
                """;
    }
}
