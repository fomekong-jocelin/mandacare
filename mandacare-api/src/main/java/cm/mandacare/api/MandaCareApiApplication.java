package cm.mandacare.api;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;

@SpringBootApplication
@ConfigurationPropertiesScan
public class MandaCareApiApplication {

    public static void main(String[] args) {
        SpringApplication.run(MandaCareApiApplication.class, args);
    }
}

