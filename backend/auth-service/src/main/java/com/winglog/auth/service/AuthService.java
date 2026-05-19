package com.winglog.auth.service;

import com.winglog.auth.dto.AuthResponse;
import com.winglog.auth.dto.LoginRequest;
import com.winglog.auth.dto.RegisterRequest;
import com.winglog.auth.model.PasswordResetToken;
import com.winglog.auth.model.User;
import com.winglog.auth.repository.PasswordResetTokenRepository;
import com.winglog.auth.repository.UserRepository;
import com.winglog.shared.util.JwtUtil;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

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
     * @throws RuntimeException om email eller användarnamn redan finns i systemet
     */
    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException("Emailadressen är redan registrerad");
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
     * loggar in en användare
     *
     * @param request innehåller användarens användarnamn och lösenord
     * @return AuthResponse innehållande JWT-token för autentisering
     * @throws RuntimeException om användanamnet inte finns eller om lösenordet inte matchar
     */
    public AuthResponse login(LoginRequest request) {
        Optional<User> user = userRepository.findByUsername(request.getUsername());
        if (user.isEmpty()) {
            throw new RuntimeException("Användarnamnet hittades inte");
        }
        if (!(passwordEncoder.matches(request.getPassword(), user.get().getPassword()))) {
            throw new RuntimeException("Fel lösenord");
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
            throw new RuntimeException("Email finns inte");
        }
        passwordResetTokenRepository.deleteByEmail(email);

        String token = UUID.randomUUID().toString();
        LocalDateTime expiresAt = LocalDateTime.now().plusMinutes(15);
        passwordResetTokenRepository.save(new PasswordResetToken(token, email, expiresAt));

        String resetLink = "http://localhost:3000/reset-password?token=" + token;
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


}
