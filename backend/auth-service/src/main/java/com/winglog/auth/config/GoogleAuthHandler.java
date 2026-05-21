/**
 * BESKRIVNING AV KLASSEN:
 * In-memory cache för engångskoder i OAuth2 Authorization Code-flödet /EF
 *
 * Syfte: JWT ska inte synas i URL efter Google-inloggning. Istället sparas
 * JWT här med en slumpad UUID som nyckel. Frontend får UUID-koden i URL,
 * POSTar den till /auth/exchange, och får tillbaka JWT i response body.
 *
 * - store(jwt): sparar JWT, returnerar UUID-kod
 * - consume(code): hämtar JWT och raderar entry (engångsanvändning)
 * - Entries går ut efter 30 sekunder
 * - ConcurrentHashMap för trådsäkerhet vid samtidiga inloggningar
 */

package com.winglog.auth.config;

import com.winglog.auth.model.User;
import com.winglog.auth.repository.UserRepository;
import com.winglog.auth.config.TokenExchangeCache;
import com.winglog.shared.util.JwtUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.Authentication;
import org.springframework.security.oauth2.core.user.OAuth2User;
import org.springframework.security.web.authentication.AuthenticationSuccessHandler;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.util.Optional;

@Component
public class GoogleAuthHandler implements AuthenticationSuccessHandler {

    // Lägger dessa som final, ändra tillbaka om ni ej vill ha så /EF
    private final UserRepository userRepository;
    private final JwtUtil jwtUtil;
    private final TokenExchangeCache tokenExchangeCache;

    @Value("${app.frontend.url}")
    private String frontendUrl;

    public GoogleAuthHandler(UserRepository userRepository,
                             JwtUtil jwtUtil,
                             TokenExchangeCache tokenExchangeCache) {
        this.userRepository = userRepository;
        this.jwtUtil = jwtUtil;
        this.tokenExchangeCache = tokenExchangeCache;
    }

    @Override
    public void onAuthenticationSuccess(HttpServletRequest request,
                                        HttpServletResponse response,
                                        Authentication authentication)
            throws IOException, ServletException {
        OAuth2User oAuth2User = (OAuth2User) authentication.getPrincipal();
        String email = oAuth2User.getAttribute("email");
        String username = authentication.getName().replace(" ", "");

        Optional<User> authUser = userRepository.findByEmail(email);
        if (authUser.isEmpty()) {
            User user = new User();
            user.setEmail(email);
            user.setProvider("google");
            user.setUsername(username);
            authUser = Optional.of(userRepository.save(user));
        }

        String token = jwtUtil.generateToken(email, authUser.get().getId().toString());

        // Lägg JWT i cachen och skicka bara engångskoden till frontend /EF
        String code = tokenExchangeCache.store(token);
        // Nu ?code= ist för #token=
        response.sendRedirect(frontendUrl + "/?code=" + code);
    }
}