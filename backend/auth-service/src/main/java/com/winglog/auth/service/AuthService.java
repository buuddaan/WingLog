package com.winglog.auth.service;

import com.winglog.auth.dto.AuthResponse;
import com.winglog.auth.dto.LoginRequest;
import com.winglog.auth.dto.RegisterRequest;
import com.winglog.auth.model.User;
import com.winglog.auth.repository.UserRepository;
import com.winglog.shared.util.JwtUtil;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class AuthService {
    private UserRepository userRepository;
    private JwtUtil jwtUtil;
    private PasswordEncoder passwordEncoder;

    public AuthService(UserRepository userRepository, JwtUtil jwtUtil, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.jwtUtil = jwtUtil;
        this.passwordEncoder = passwordEncoder;
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

        userRepository.save(user);
        String token = jwtUtil.generateToken(user.getEmail());
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
        String token = jwtUtil.generateToken(user.get().getEmail());
        return new AuthResponse(token);
    }

}
