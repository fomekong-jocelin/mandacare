package cm.mandacare.api.module.patient;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;

record UpdateTariffItemRequest(

        @NotBlank(message = "Le nom est obligatoire.")
        @Size(max = 180, message = "Le nom ne doit pas dépasser 180 caractères.")
        String name,

        @Size(max = 120, message = "La catégorie ne doit pas dépasser 120 caractères.")
        String category,

        @NotNull(message = "Le prix est obligatoire.")
        @DecimalMin(value = "0.00", message = "Le prix ne peut pas être négatif.")
        BigDecimal price,

        @NotNull(message = "Le statut actif est obligatoire.")
        Boolean active
) {
}
