package cm.mandacare.api.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
class OpenApiConfiguration {

    @Bean
    OpenAPI mandacareOpenApi() {
        return new OpenAPI()
                .info(new Info()
                        .title("MandaCare API")
                        .version("0.1.0")
                        .description("API MVP mobile/tablette pour MandaCare"));
    }
}

