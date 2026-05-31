package cm.mandacare.api.module.center;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

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
class CenterSettingsControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void adminUpdatesCenterSettings() throws Exception {
        mockMvc.perform(put("/api/v1/settings/center")
                        .with(user("admin").roles("ADMIN"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "name": "Clinique Manda",
                                  "slogan": "Soigner vite et bien",
                                  "phone": "+237 699 000 111",
                                  "email": "contact@clinique-manda.cm",
                                  "city": "Douala",
                                  "address": "Logbessou, carrefour santé",
                                  "poBox": "BP 1234 Douala",
                                  "rccm": "RC/DLA/2026/A/123",
                                  "taxpayerNumber": "M012345678901A"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Clinique Manda"))
                .andExpect(jsonPath("$.slogan").value("Soigner vite et bien"))
                .andExpect(jsonPath("$.phone").value("+237 699 000 111"))
                .andExpect(jsonPath("$.email").value("contact@clinique-manda.cm"))
                .andExpect(jsonPath("$.city").value("Douala"))
                .andExpect(jsonPath("$.address").value("Logbessou, carrefour santé"))
                .andExpect(jsonPath("$.poBox").value("BP 1234 Douala"))
                .andExpect(jsonPath("$.rccm").value("RC/DLA/2026/A/123"))
                .andExpect(jsonPath("$.taxpayerNumber").value("M012345678901A"));

        mockMvc.perform(get("/api/v1/settings/center")
                        .with(user("doctor").roles("MEDECIN")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Clinique Manda"))
                .andExpect(jsonPath("$.city").value("Douala"))
                .andExpect(jsonPath("$.rccm").value("RC/DLA/2026/A/123"));
    }

    @Test
    void nonAdminCannotUpdateCenterSettings() throws Exception {
        mockMvc.perform(put("/api/v1/settings/center")
                        .with(user("doctor").roles("MEDECIN"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "name": "Clinique Manda",
                                  "slogan": "Soigner vite et bien",
                                  "city": "Douala",
                                  "address": "Logbessou"
                                }
                                """))
                .andExpect(status().isForbidden());
    }
}
