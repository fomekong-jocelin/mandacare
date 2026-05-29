package cm.mandacare.api.module.patient;

import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.hasItem;
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.notNullValue;
import static org.hamcrest.Matchers.nullValue;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.UUID;
import com.jayway.jsonpath.JsonPath;
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
class PatientControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private AuditLogRepository auditLogs;

    @Test
    void createsPatientWithInitialVisit() throws Exception {
        mockMvc.perform(post("/api/v1/patients")
                        .with(user("doctor"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(validPatientJson("Awa", "Diop", "+221 77 420 18 92")))
                .andExpect(status().isCreated())
                .andExpect(header().string("Location", containsString("/api/v1/patients/")))
                .andExpect(jsonPath("$.id").isNotEmpty())
                .andExpect(jsonPath("$.patientNumber").isNotEmpty())
                .andExpect(jsonPath("$.fullName").value("Awa Diop"))
                .andExpect(jsonPath("$.latestVisit.status").value("WAITING"))
                .andExpect(jsonPath("$.latestVisit.priority").value("SURVEILLANCE"));
    }

    @Test
    void listsPatientsUsingSearchTerm() throws Exception {
        mockMvc.perform(post("/api/v1/patients")
                        .with(user("doctor"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(validPatientJson("Fatou", "Searchable", "+221 70 000 00 11")))
                .andExpect(status().isCreated());

        mockMvc.perform(get("/api/v1/patients")
                        .with(user("doctor"))
                        .param("search", "searchable")
                        .param("limit", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].fullName").value("Fatou Searchable"))
                .andExpect(jsonPath("$[0].latestVisit.reason").value("Suivi prénatal"));
    }

    @Test
    void listsTodayQueueFromOpenVisits() throws Exception {
        mockMvc.perform(post("/api/v1/patients")
                        .with(user("doctor"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(validPatientJson("Queue", "Visible", "+221 70 000 00 12")))
                .andExpect(status().isCreated());

        mockMvc.perform(get("/api/v1/patients/queue/today")
                        .with(user("doctor"))
                        .param("limit", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[*].fullName", hasItem("Queue Visible")))
                .andExpect(jsonPath("$[*].latestVisit.status", hasItem("WAITING")));
    }

    @Test
    void createsVisitForExistingPatient() throws Exception {
        String patientBody = mockMvc.perform(post("/api/v1/patients")
                        .with(user("doctor"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(validPatientJson("Existing", "Patient", "+221 70 000 00 13")))
                .andExpect(status().isCreated())
                .andReturn()
                .getResponse()
                .getContentAsString();
        String patientId = JsonPath.read(patientBody, "$.id");

        mockMvc.perform(post("/api/v1/patients/{id}/visits", patientId)
                        .with(user("doctor"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "reason": "Douleur abdominale",
                                  "priority": "URGENT",
                                  "targetService": "VITALS"
                                }
                """))
                .andExpect(status().isCreated())
                .andExpect(header().string("Location", containsString("/visits/")))
                .andExpect(jsonPath("$.id").value(patientId))
                .andExpect(jsonPath("$.latestVisit.id", notNullValue()))
                .andExpect(jsonPath("$.latestVisit.reason").value("Douleur abdominale"))
                .andExpect(jsonPath("$.latestVisit.priority").value("URGENT"))
                .andExpect(jsonPath("$.latestVisit.targetService").value("VITALS"))
                .andExpect(jsonPath("$.latestVisit.status").value("WAITING"));
    }

    @Test
    void changesVisitStatus() throws Exception {
        String patientBody = mockMvc.perform(post("/api/v1/patients")
                        .with(user("doctor"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(validPatientJson("Status", "Patient", "+221 70 000 00 14")))
                .andExpect(status().isCreated())
                .andReturn()
                .getResponse()
                .getContentAsString();
        String visitId = JsonPath.read(patientBody, "$.latestVisit.id");

        mockMvc.perform(patch("/api/v1/visits/{id}/status", visitId)
                        .with(user("doctor"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "status": "IN_CONSULTATION"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.fullName").value("Status Patient"))
                .andExpect(jsonPath("$.latestVisit.id").value(visitId))
                .andExpect(jsonPath("$.latestVisit.status").value("IN_CONSULTATION"));
    }

    @Test
    void createsVitalsAndReturnsLatestForVisit() throws Exception {
        String patientBody = mockMvc.perform(post("/api/v1/patients")
                        .with(user("doctor"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(validPatientJson("Vitals", "Patient", "+221 70 000 00 15")))
                .andExpect(status().isCreated())
                .andReturn()
                .getResponse()
                .getContentAsString();
        String visitId = JsonPath.read(patientBody, "$.latestVisit.id");

        mockMvc.perform(post("/api/v1/visits/{id}/vitals", visitId)
                        .with(user("nurse"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "temperature": 37.2,
                                  "systolicPressure": 120,
                                  "diastolicPressure": 80,
                                  "pulse": 78,
                                  "respiratoryRate": 18,
                                  "oxygenSaturation": 98,
                                  "weight": 70.00,
                                  "height": 175.00,
                                  "bloodGlucose": 0.95
                                }
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.visitId").value(visitId))
                .andExpect(jsonPath("$.temperature").value(37.2))
                .andExpect(jsonPath("$.bmi").value(22.86));

        mockMvc.perform(get("/api/v1/visits/{id}/vitals/latest", visitId)
                        .with(user("doctor")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.visitId").value(visitId))
                .andExpect(jsonPath("$.pulse").value(78))
                .andExpect(jsonPath("$.bmi").value(22.86));

        mockMvc.perform(get("/api/v1/patients/queue/today")
                        .with(user("doctor"))
                        .param("limit", "20"))
                .andExpect(status().isOk())
                .andExpect(jsonPath(
                        "$[?(@.latestVisit.id == '%s')].latestVisit.status".formatted(visitId),
                        hasItem("IN_CONSULTATION")
                ));
    }

    @Test
    void createsConsultationAndUpdatesVisitStatus() throws Exception {
        String patientBody = mockMvc.perform(post("/api/v1/patients")
                        .with(user("doctor"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(validPatientJson("Consulted", "Patient", "+221 70 000 00 16")))
                .andExpect(status().isCreated())
                .andReturn()
                .getResponse()
                .getContentAsString();
        String patientId = JsonPath.read(patientBody, "$.id");
        String visitId = JsonPath.read(patientBody, "$.latestVisit.id");

        mockMvc.perform(post("/api/v1/visits/{id}/vitals", visitId)
                        .with(user("nurse"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "temperature": 37.2,
                                  "pulse": 78,
                                  "weight": 70.00,
                                  "height": 175.00
                                }
                                """))
                .andExpect(status().isCreated());

        mockMvc.perform(post("/api/v1/visits/{id}/consultations", visitId)
                        .with(user("doctor"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "symptoms": "Céphalées depuis deux jours",
                                  "clinicalExam": "Patient conscient, stable",
                                  "diagnosis": "Céphalées simples",
                                  "advice": "Hydratation et surveillance",
                                  "decision": "RELEASE_PATIENT"
                                }
                                """))
                .andExpect(status().isCreated())
                .andExpect(header().string("Location", containsString("/consultations/")))
                .andExpect(jsonPath("$.visitId").value(visitId))
                .andExpect(jsonPath("$.diagnosis").value("Céphalées simples"))
                .andExpect(jsonPath("$.decision").value("RELEASE_PATIENT"))
                .andExpect(jsonPath("$.visitStatus").value("RELEASED"));

        mockMvc.perform(get("/api/v1/patients/{id}", patientId)
                        .with(user("doctor")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.latestVisit.id").value(visitId))
                .andExpect(jsonPath("$.latestVisit.status").value("RELEASED"));
    }

    @Test
    void handlesConsultationDraftAndValidation() throws Exception {
        String patientResponse = mockMvc.perform(post("/api/v1/patients")
                        .with(user("doctor"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "firstName": "Brouillon",
                                  "lastName": "Patient",
                                  "sex": "MALE",
                                  "declaredAge": 30,
                                  "phone": "699000000",
                                  "city": "Yaoundé",
                                  "emergencyContactPhone": "677000000",
                                  "arrivalReason": "Observation",
                                  "priority": "STANDARD"
                                }
                                """))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();

        String visitId = JsonPath.read(patientResponse, "$.latestVisit.id");

        // 1. Create a draft consultation (missing clinicalExam and diagnosis)
        mockMvc.perform(post("/api/v1/visits/{id}/consultations", visitId)
                        .with(user("doctor"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "symptoms": "Toux légère",
                                  "clinicalExam": "",
                                  "diagnosis": "",
                                  "advice": "",
                                  "decision": "KEEP_IN_CONSULTATION",
                                  "status": "DRAFT"
                                }
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.status").value("DRAFT"))
                .andExpect(jsonPath("$.symptoms").value("Toux légère"))
                .andExpect(jsonPath("$.clinicalExam").value(nullValue()))
                .andExpect(jsonPath("$.visitStatus").value("IN_CONSULTATION"));

        // 2. Try validating with incomplete fields (should fail)
        mockMvc.perform(post("/api/v1/visits/{id}/consultations", visitId)
                        .with(user("doctor"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "symptoms": "Toux légère",
                                  "clinicalExam": "",
                                  "diagnosis": "",
                                  "advice": "",
                                  "decision": "RELEASE_PATIENT",
                                  "status": "VALIDATED"
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("CLINICAL_EXAM_REQUIRED"));

        // 3. Update the draft with complete details and validate
        mockMvc.perform(post("/api/v1/visits/{id}/consultations", visitId)
                        .with(user("doctor"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "symptoms": "Toux légère et fièvre",
                                  "clinicalExam": "Gorge rouge",
                                  "diagnosis": "Pharyngite",
                                  "advice": "Paracétamol",
                                  "decision": "KEEP_IN_CONSULTATION",
                                  "status": "VALIDATED"
                                }
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.status").value("VALIDATED"))
                .andExpect(jsonPath("$.symptoms").value("Toux légère et fièvre"))
                .andExpect(jsonPath("$.clinicalExam").value("Gorge rouge"))
                .andExpect(jsonPath("$.diagnosis").value("Pharyngite"))
                .andExpect(jsonPath("$.visitStatus").value("IN_CONSULTATION"));

        // 4. Try updating the validated consultation (should fail with conflict)
        mockMvc.perform(post("/api/v1/visits/{id}/consultations", visitId)
                        .with(user("doctor"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "symptoms": "Autre chose",
                                  "clinicalExam": "Examen",
                                  "diagnosis": "Diagnostic",
                                  "decision": "RELEASE_PATIENT",
                                  "status": "DRAFT"
                                }
                                """))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("CONSULTATION_ALREADY_VALIDATED"));
    }

    @Test
    void handlesConsultationCorrection() throws Exception {
        String patientResponse = mockMvc.perform(post("/api/v1/patients")
                        .with(user("doctor"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "firstName": "Correction",
                                  "lastName": "Patient",
                                  "sex": "FEMALE",
                                  "declaredAge": 45,
                                  "phone": "699111222",
                                  "city": "Yaoundé",
                                  "emergencyContactPhone": "677111222",
                                  "arrivalReason": "Consultation",
                                  "priority": "STANDARD"
                                }
                                """))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();

        String visitId = JsonPath.read(patientResponse, "$.latestVisit.id");

        // 1. Create and validate consultation
        mockMvc.perform(post("/api/v1/visits/{id}/consultations", visitId)
                        .with(user("doctor"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "symptoms": "Fièvre élevée",
                                  "clinicalExam": "Tympan congestif",
                                  "diagnosis": "Otite",
                                  "advice": "Gouttes auriculaires",
                                  "decision": "KEEP_IN_CONSULTATION",
                                  "status": "VALIDATED"
                                }
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.status").value("VALIDATED"));

        // 2. Try modifying without a motif (should fail)
        mockMvc.perform(post("/api/v1/visits/{id}/consultations", visitId)
                        .with(user("doctor"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "symptoms": "Fièvre élevée corrigée",
                                  "clinicalExam": "Tympan congestif",
                                  "diagnosis": "Otite externe",
                                  "advice": "Gouttes auriculaires",
                                  "decision": "KEEP_IN_CONSULTATION",
                                  "status": "VALIDATED"
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("CORRECTION_MOTIF_REQUIRED"));

        // 3. Modify with correction motif (should succeed)
        long initialLogsCount = auditLogs.count();

        mockMvc.perform(post("/api/v1/visits/{id}/consultations", visitId)
                        .with(user("doctor"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "symptoms": "Fièvre élevée corrigée",
                                  "clinicalExam": "Tympan congestif",
                                  "diagnosis": "Otite externe",
                                  "advice": "Gouttes auriculaires",
                                  "decision": "KEEP_IN_CONSULTATION",
                                  "status": "VALIDATED",
                                  "correctionMotif": "Erreur de frappe sur le diagnostic"
                                }
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.status").value("CORRECTED"))
                .andExpect(jsonPath("$.diagnosis").value("Otite externe"));

        // 4. Verify audit log entry was created
        org.junit.jupiter.api.Assertions.assertEquals(initialLogsCount + 1, auditLogs.count());
    }

    @Test
    void managesPrescriptionWorkflow() throws Exception {
        // 1. Create patient and get visitId
        String patientBody = mockMvc.perform(post("/api/v1/patients")
                        .with(user("doctor"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(validPatientJson("Presc", "Patient", "+221 70 000 00 99")))
                .andExpect(status().isCreated())
                .andReturn()
                .getResponse()
                .getContentAsString();
        String visitId = JsonPath.read(patientBody, "$.latestVisit.id");

        // 2. Create consultation draft (needed to link prescription)
        String consultationBody = mockMvc.perform(post("/api/v1/visits/{id}/consultations", visitId)
                        .with(user("doctor"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "symptoms": "Toux",
                                  "clinicalExam": "Examen pulmonaire",
                                  "diagnosis": "Bronchite",
                                  "decision": "RELEASE_PATIENT",
                                  "status": "DRAFT"
                                }
                                """))
                .andExpect(status().isCreated())
                .andReturn()
                .getResponse()
                .getContentAsString();
        String consultationId = JsonPath.read(consultationBody, "$.id");

        // 3. Save a draft prescription
        mockMvc.perform(post("/api/v1/consultations/{id}/prescription", consultationId)
                        .with(user("doctor"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "status": "DRAFT",
                                  "items": [
                                    {
                                      "drugName": "Paracétamol",
                                      "form": "Comprimé",
                                      "dosage": "500mg",
                                      "frequency": "3x/jour",
                                      "duration": "5 jours",
                                      "quantity": 15,
                                      "instructions": "À prendre après le repas"
                                    }
                                  ]
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id", notNullValue()))
                .andExpect(jsonPath("$.status").value("DRAFT"))
                .andExpect(jsonPath("$.items", hasSize(1)))
                .andExpect(jsonPath("$.items[0].drugName").value("Paracétamol"));

        // 4. Save a validated prescription (should succeed)
        mockMvc.perform(post("/api/v1/consultations/{id}/prescription", consultationId)
                        .with(user("doctor"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "status": "VALIDATED",
                                  "items": [
                                    {
                                      "drugName": "Paracétamol",
                                      "form": "Comprimé",
                                      "dosage": "500mg",
                                      "frequency": "3x/jour",
                                      "duration": "5 jours",
                                      "quantity": 15,
                                      "instructions": "À prendre après le repas"
                                    },
                                    {
                                      "drugName": "Amoxicilline",
                                      "form": "Gélule",
                                      "dosage": "1g",
                                      "frequency": "2x/jour",
                                      "duration": "7 jours",
                                      "quantity": 14,
                                      "instructions": "Respecter les heures"
                                    }
                                  ]
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("VALIDATED"))
                .andExpect(jsonPath("$.items", hasSize(2)));

        // 5. Get prescription
        mockMvc.perform(get("/api/v1/consultations/{id}/prescription", consultationId)
                        .with(user("doctor")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("VALIDATED"))
                .andExpect(jsonPath("$.items", hasSize(2)));

        // 6. Get PDF bytes
        mockMvc.perform(get("/api/v1/consultations/{id}/prescription/pdf", consultationId)
                        .with(user("doctor")))
                .andExpect(status().isOk())
                .andExpect(header().string("Content-Type", "application/pdf"));
    }

    @Test
    void rejectsInvalidPatientCreationRequest() throws Exception {
        mockMvc.perform(post("/api/v1/patients")
                        .with(user("doctor"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "firstName": "",
                                  "lastName": "Diop",
                                  "sex": "FEMALE",
                                  "phone": "",
                                  "arrivalReason": "",
                                  "priority": "STANDARD"
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"));
    }

    @Test
    void returnsTimelineForPatient() throws Exception {
        String patientBody = mockMvc.perform(post("/api/v1/patients")
                        .with(user("doctor"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(validPatientJson("Timeline", "Patient", "+221 70 000 00 20")))
                .andExpect(status().isCreated())
                .andReturn()
                .getResponse()
                .getContentAsString();
        String patientId = JsonPath.read(patientBody, "$.id");
        String visitId = JsonPath.read(patientBody, "$.latestVisit.id");

        mockMvc.perform(get("/api/v1/patients/{id}/timeline", patientId)
                        .with(user("doctor")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].visitId").value(visitId))
                .andExpect(jsonPath("$[0].reason").value("Suivi prénatal"))
                .andExpect(jsonPath("$[0].status").value("WAITING"));
    }

    @Test
    void returnsNotFoundForUnknownPatient() throws Exception {
        mockMvc.perform(get("/api/v1/patients/{id}", UUID.randomUUID())
                        .with(user("doctor")))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("PATIENT_NOT_FOUND"));
    }

    private String validPatientJson(String firstName, String lastName, String phone) {
        return """
                {
                  "firstName": "%s",
                  "lastName": "%s",
                  "sex": "FEMALE",
                  "declaredAge": 28,
                  "phone": "%s",
                  "city": "Dakar",
                  "district": "Plateau",
                  "emergencyContactName": "Moussa Diop",
                  "emergencyContactPhone": "+221 77 111 22 33",
                  "arrivalReason": "Suivi prénatal",
                  "priority": "SURVEILLANCE",
                  "targetService": "CONSULTATION"
                }
                """.formatted(firstName, lastName, phone);
    }
}
