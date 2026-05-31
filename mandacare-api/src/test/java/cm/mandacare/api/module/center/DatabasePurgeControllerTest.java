package cm.mandacare.api.module.center;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

@ActiveProfiles("test")
@SpringBootTest
@AutoConfigureMockMvc
class DatabasePurgeControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void adminCanPurgeDatabase() throws Exception {
        mockMvc.perform(post("/api/v1/settings/database/purge")
                        .with(user("admin").roles("ADMIN")))
                .andExpect(status().isOk());
    }

    @Test
    void nonAdminCannotPurgeDatabase() throws Exception {
        mockMvc.perform(post("/api/v1/settings/database/purge")
                        .with(user("doctor").roles("MEDECIN")))
                .andExpect(status().isForbidden());
    }

    @Test
    void unauthenticatedCannotPurgeDatabase() throws Exception {
        mockMvc.perform(post("/api/v1/settings/database/purge"))
                .andExpect(status().isUnauthorized());
    }
}
