package cm.mandacare.api.module.center;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class CenterSettingsService {

    private static final int CENTER_SETTINGS_ID = 1;

    private final JdbcTemplate jdbcTemplate;
    private final CenterSettingsProperties properties;

    public CenterSettingsService(JdbcTemplate jdbcTemplate, CenterSettingsProperties properties) {
        this.jdbcTemplate = jdbcTemplate;
        this.properties = properties;
    }

    @Transactional(readOnly = true)
    public CenterSettingsResponse currentSettings() {
        return jdbcTemplate.query(
                """
                SELECT name, slogan, phone, email, city, address, po_box, rccm, taxpayer_number
                FROM center_settings
                WHERE id = ?
                """,
                (rs) -> {
                    if (rs.next()) {
                        return new CenterSettingsResponse(
                                rs.getString("name"),
                                rs.getString("slogan"),
                                rs.getString("phone"),
                                rs.getString("email"),
                                rs.getString("city"),
                                rs.getString("address"),
                                rs.getString("po_box"),
                                rs.getString("rccm"),
                                rs.getString("taxpayer_number")
                        );
                    }
                    return fallbackSettings();
                },
                CENTER_SETTINGS_ID
        );
    }

    @Transactional
    CenterSettingsResponse update(UpdateCenterSettingsRequest request) {
        jdbcTemplate.update(
                """
                UPDATE center_settings
                SET name = ?,
                    slogan = ?,
                    phone = ?,
                    email = ?,
                    city = ?,
                    address = ?,
                    po_box = ?,
                    rccm = ?,
                    taxpayer_number = ?,
                    updated_at = CURRENT_TIMESTAMP
                WHERE id = ?
                """,
                request.name().trim(),
                request.slogan().trim(),
                clean(request.phone()),
                clean(request.email()),
                request.city().trim(),
                clean(request.address()),
                clean(request.poBox()),
                clean(request.rccm()),
                clean(request.taxpayerNumber()),
                CENTER_SETTINGS_ID
        );
        return currentSettings();
    }

    private CenterSettingsResponse fallbackSettings() {
        return new CenterSettingsResponse(
                properties.getName(),
                properties.getSlogan(),
                null,
                null,
                properties.getCity(),
                null,
                null,
                null,
                null
        );
    }

    private String clean(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return value.trim();
    }
}
