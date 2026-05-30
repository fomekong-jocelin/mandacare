package cm.mandacare.api.module.auth;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
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
class AuthControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void logsInDefaultAdmin() throws Exception {
        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "username": "admin",
                                  "password": "admin123"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accessToken").isNotEmpty())
                .andExpect(jsonPath("$.tokenType").value("Bearer"))
                .andExpect(jsonPath("$.displayName").value("Dr Manda"))
                .andExpect(jsonPath("$.profile.username").value("admin"))
                .andExpect(jsonPath("$.profile.displayName").value("Dr Manda"))
                .andExpect(jsonPath("$.profile.role.code").value("ADMIN"))
                .andExpect(jsonPath("$.profile.role.label").value("Administrateur"));
    }

    @Test
    void rejectsInvalidCredentials() throws Exception {
        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "username": "admin",
                                  "password": "bad-password"
                                }
                                """))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("AUTH_INVALID_CREDENTIALS"));
    }

    @Test
    void adminManagesTeamUsers() throws Exception {
        String token = loginToken();

        mockMvc.perform(get("/api/v1/auth/roles")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[?(@.code == 'MEDECIN')]").exists())
                .andExpect(jsonPath("$[?(@.code == 'CAISSIER')]").exists())
                .andExpect(jsonPath("$[?(@.code == 'INFIRMIER')]").exists());

        String created = mockMvc.perform(post("/api/v1/auth/users")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "firstName": "Awa",
                                  "lastName": "Ndiaye",
                                  "phone": "690000001",
                                  "email": "awa.ndiaye@example.org",
                                  "username": "awa.ndiaye",
                                  "password": "secret123",
                                  "roleCode": "MEDECIN"
                                }
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.displayName").value("Awa Ndiaye"))
                .andExpect(jsonPath("$.role.code").value("MEDECIN"))
                .andReturn()
                .getResponse()
                .getContentAsString();

        String id = objectMapper.readTree(created).get("id").asText();

        mockMvc.perform(patch("/api/v1/auth/users/" + id)
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "firstName": "Awa",
                                  "lastName": "Ndiaye",
                                  "phone": "690000001",
                                  "email": "awa.ndiaye@example.org",
                                  "username": "awa.ndiaye",
                                  "roleCode": "INFIRMIER",
                                  "status": "ACTIVE"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.role.code").value("INFIRMIER"));

        String staffToken = loginToken("awa.ndiaye", "secret123");
        mockMvc.perform(get("/api/v1/auth/users")
                        .header("Authorization", "Bearer " + staffToken))
                .andExpect(status().isForbidden());
    }

    private String loginToken() throws Exception {
        return loginToken("admin", "admin123");
    }

    private String loginToken(String username, String password) throws Exception {
        String login = mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "username": "%s",
                                  "password": "%s"
                                }
                                """.formatted(username, password)))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString();
        JsonNode json = objectMapper.readTree(login);
        return json.get("accessToken").asText();
    }
}
