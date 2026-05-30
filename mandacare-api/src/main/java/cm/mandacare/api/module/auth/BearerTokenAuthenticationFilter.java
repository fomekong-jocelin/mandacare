package cm.mandacare.api.module.auth;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;
import java.util.Locale;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

@Component
public class BearerTokenAuthenticationFilter extends OncePerRequestFilter {

    private static final String BEARER_PREFIX = "Bearer ";
    private final AuthTokenService tokens;
    private final AuthUserRepository users;

    BearerTokenAuthenticationFilter(AuthTokenService tokens, AuthUserRepository users) {
        this.tokens = tokens;
        this.users = users;
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {
        String authorization = request.getHeader("Authorization");
        if (authorization != null && authorization.startsWith(BEARER_PREFIX)) {
            authenticate(authorization.substring(BEARER_PREFIX.length()));
        }
        filterChain.doFilter(request, response);
    }

    private void authenticate(String rawToken) {
        tokens.resolveUsername(rawToken)
                .flatMap(users::findByUsernameIgnoreCase)
                .filter(AuthUserEntity::active)
                .map(user -> new UsernamePasswordAuthenticationToken(
                        user.username(),
                        rawToken,
                        List.of(
                                new SimpleGrantedAuthority("ROLE_USER"),
                                new SimpleGrantedAuthority("ROLE_" + user.role().code().toUpperCase(Locale.ROOT))
                        )
                ))
                .ifPresent(SecurityContextHolder.getContext()::setAuthentication);
    }
}
