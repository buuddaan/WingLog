package com.winglog.auth.service;

import com.winglog.auth.dto.AuthResponse;
import com.winglog.auth.dto.LoginRequest;
import com.winglog.auth.dto.RegisterRequest;
import com.winglog.auth.model.PasswordResetToken;
import com.winglog.auth.model.User;
import com.winglog.auth.repository.PasswordResetTokenRepository;
import com.winglog.auth.repository.UserRepository;
import com.winglog.shared.util.JwtUtil;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

@Service
public class AuthService {
    private UserRepository userRepository;
    private JwtUtil jwtUtil;
    private PasswordEncoder passwordEncoder;
    private PasswordResetTokenRepository passwordResetTokenRepository;
    private EmailService emailService;
    @Value("${app.frontend.url}")
    private String frontendUrl;

    public AuthService(UserRepository userRepository, JwtUtil jwtUtil, PasswordEncoder passwordEncoder, PasswordResetTokenRepository passwordResetTokenRepository, EmailService emailService) {
        this.userRepository = userRepository;
        this.jwtUtil = jwtUtil;
        this.passwordEncoder = passwordEncoder;
        this.passwordResetTokenRepository = passwordResetTokenRepository;
        this.emailService = emailService;
    }

    /**
     * En ny användare skapas
     *
     * @param request innehållande den nya användarens email, användarnamn och lösenord
     * @return AuthResponse innehållande JWT-token
     * @throws RuntimeException om email eller användarnamn redan finns i systemet,
     *                          eller om någon av fälten inte uppfyller valideringskraven
     */
    public AuthResponse register(RegisterRequest request) {
        validateRegisterRequest(request); // valideras innan vi gör databasanrop, för att slippa onödig DB-trafik vid tydligt ogiltig input /EF

        if (userRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException("Email-adressen är redan registrerad");
        }

        if (userRepository.existsByUsername(request.getUsername())) {
            throw new RuntimeException("Användarnamnet finns redan");
        }

        User user = new User();
        user.setEmail(request.getEmail());
        user.setUsername(request.getUsername());
        user.setPassword(passwordEncoder.encode(request.getPassword()));
        user.setProvider("local");

        user = userRepository.save(user); // Hämtar tillbaka användaren med det DB-genererade UUID:t /EF
        String token = jwtUtil.generateToken(user.getEmail(), user.getId().toString()); // userId bakas in i JWT för stateless identifiering /EF
        return new AuthResponse(token);
    }

    /**
     * Validerar fälten i en registreringsförfrågan.
     * Kontrollerar att email, användarnamn och lösenord finns och uppfyller formatkraven.
     *
     * @param request registreringsförfrågan som ska valideras
     * @throws RuntimeException om någon kontroll misslyckas
     */
    private void validateRegisterRequest(RegisterRequest request) {
        // Email: får inte vara tomt och måste innehålla @ och en punkt efter @ /EF
        String email = request.getEmail();
        if (email == null || email.isBlank()) {
            throw new RuntimeException("Email får inte vara tom");
        }

        // Kontrollerar så inte mail börjar med @gmail.com tex, utan är riktig mail
        int atIndex = email.indexOf('@');

        // Kontrollerar så att det finns en punkt efter @, så det inte blir mailaddress@ingenpunkt och att en mail inte slutar på . som hej@gmail.
        if (atIndex < 1 || email.indexOf('.', atIndex) < 0 || email.endsWith(".")) {
            throw new RuntimeException("Ogiltig emailadress");
            // OBS: Kan fortfarande skicka in tex a@a.a som giltig mail, vill vi sätta strängare kontroller här sen också?? /EF
        }

        // Användarnamn: 3-30 tecken, endast bokstäver/siffror/_/- (skyddar mot konstiga tecken i URL:er och visningar) /EF
        String username = request.getUsername();
        if (username == null || username.isBlank()) {
            throw new RuntimeException("Användarnamn får inte vara tomt");
        }
        if (username.length() < 3 || username.length() > 30) {
            throw new RuntimeException("Användarnamn måste vara mellan 3 och 30 tecken");
        }
        for (int i = 0; i < username.length(); i++) {
            char c = username.charAt(i);
            boolean isAllowed = (c >= 'a' && c <= 'z')
                    || (c >= 'A' && c <= 'Z')
                    || (c >= '0' && c <= '9')
                    || c == '_' || c == '-';
            if (!isAllowed) {
                throw new RuntimeException("Användarnamn får endast innehålla bokstäver, siffror, _ och -");
            }
        }

        String password = request.getPassword();
        if (password == null || password.isBlank()) {
            throw new RuntimeException("Lösenord får inte vara tomt");
        }
        // Lösenord: minst 8 tecken enligt OWASP-rekommendation /EF
        if (password.length() < 8) {
            throw new RuntimeException("Lösenord måste vara minst 8 tecken");
        }
        // Kanske onödigt men max 100 (BCrypt har intern gräns på 72 bytes, max 100 hindrar också DOS via gigantiska strängar) /EF
        if (password.length() > 100) {
            throw new RuntimeException("Lösenord får vara max 100 tecken");
        }
    }

    /**
     * Loggar in en användare
     *
     * @param request innehåller användarens användarnamn och lösenord
     * @return AuthResponse innehållande JWT-token för autentisering
     * @throws RuntimeException om användanamnet inte finns, lösenordet inte matchar,
     *                          eller om kontot är registrerat via extern provider (Google)
     */
    public AuthResponse login(LoginRequest request) {
        Optional<User> user = userRepository.findByUsername(request.getUsername());
        if (user.isEmpty()) {
            throw new RuntimeException("Fel användarnamn eller lösenord");
        }
        // Provider-check mellan username-lookup och lösenordskontroll så om kontot inte är "local" får man ej chans att skicka in tomma lösenord (då de står lagrade som NULL i databasen) /EF
        if (!"local".equals(user.get().getProvider())) {
            throw new RuntimeException("Logga in med Google istället");
        }
        if (!(passwordEncoder.matches(request.getPassword(), user.get().getPassword()))) {
            throw new RuntimeException("Fel användarnamn eller lösenord");
        }
        String token = jwtUtil.generateToken(user.get().getEmail(), user.get().getId().toString()); // userId bakas in i JWT för stateless identifiering /EF
        return new AuthResponse(token);
    }

    /**
     * Skapar en återställningstoken och skickar ett email till användaren med en återställningslänk
     *
     * @param email emailadressen till användaren som vill återställa sitt lösenord
     * @throws RuntimeException om emailadressen inte finns.
     */
    public void forgotPassword(String email){
        Optional<User> user = userRepository.findByEmail(email);
        if (user.isEmpty()){
            return;
        }
        passwordResetTokenRepository.deleteByEmail(email);

        String token = UUID.randomUUID().toString();
        LocalDateTime expiresAt = LocalDateTime.now().plusMinutes(15);
        passwordResetTokenRepository.save(new PasswordResetToken(token, email, expiresAt));

        String resetLink = frontendUrl + "/reset-password#token=" + token;
        emailService.sendPassword(email, resetLink);
    }

    /**
     * Återställer användaren lösenord med hjälp av en återställningstoken.
     * Tokonen kontrolleras så att den inte har gått ut.
     *
     * @param token som skickades vi mail
     * @param newPassword det nya lösenordet som ersätter det gamla lösenordet.
     * @throws RuntimeException om tokonen inte gäller längre eller har gått ut.
     */
    public void resetPassword(String token, String newPassword){
        Optional<PasswordResetToken> resetToken = passwordResetTokenRepository.findByToken(token);
        if (resetToken.isEmpty()){
            throw new RuntimeException("Ogiltig token");
        }
        if (resetToken.get().getExpiresAt().isBefore(LocalDateTime.now())){
            throw new RuntimeException("Token har gått ut");
        }

        Optional<User> user = userRepository.findByEmail(resetToken.get().getEmail());
        user.get().setPassword(passwordEncoder.encode(newPassword));
        userRepository.save(user.get());
        passwordResetTokenRepository.deleteByEmail(resetToken.get().getEmail());
    }

    /**
     * Raderar en användare och dennes återställningtoken baserat på användarens id
     * @param userId id som tillhör användaren som ska raderas
     * @throws ResponseStatusException om användaren inte hittas
     */
    @Transactional
    public void deleteUser(UUID userId) {
        User user = userRepository.findById(userId).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Användaren hittades inte"));
        passwordResetTokenRepository.deleteByEmail(user.getEmail());
        userRepository.deleteById(userId);
    }
}