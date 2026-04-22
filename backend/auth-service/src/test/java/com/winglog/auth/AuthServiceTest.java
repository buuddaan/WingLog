package com.winglog.auth;

import com.winglog.auth.dto.AuthResponse;
import com.winglog.auth.dto.LoginRequest;
import com.winglog.auth.dto.RegisterRequest;
import com.winglog.auth.model.User;
import com.winglog.auth.repository.UserRepository;
import com.winglog.auth.service.AuthService;
import com.winglog.shared.util.JwtUtil;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Optional;

import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
public class AuthServiceTest {
    @Mock
    private JwtUtil jwtUtil;
    @Mock
    private UserRepository userRepository;
    @Mock
    private PasswordEncoder passwordEncoder;

    @InjectMocks
    private AuthService authService;

    @Test
    void registerSuccess() {
        RegisterRequest request = new RegisterRequest("test123@test.com", "testUsername", "testPassword");

        when(userRepository.existsByEmail("test123@test.com")).thenReturn(false);
        when(userRepository.existsByUsername("testUsername")).thenReturn(false);
        when(passwordEncoder.encode("testPassword")).thenReturn("KrypteratPassword");
        when(jwtUtil.generateToken("test123@test.com")).thenReturn("FejkToken");

        AuthResponse result = authService.register(request);

        Assertions.assertNotNull(result);
        Assertions.assertEquals("FejkToken", result.getToken());
    }

    @Test
    void emailAlreadyExists() {
        RegisterRequest request = new RegisterRequest("test123@test.com", "testUsername", "testPassword");

        when(userRepository.existsByEmail("test123@test.com")).thenReturn(true);

        Assertions.assertThrows(RuntimeException.class, () -> authService.register(request));

    }

    @Test
    void usernameAlreadyExists() {
        RegisterRequest request = new RegisterRequest("test123@test.com", "testUsername", "testPassword");

        when(userRepository.existsByEmail("test123@test.com")).thenReturn(false);
        when(userRepository.existsByUsername("testUsername")).thenReturn(true);

        Assertions.assertThrows(RuntimeException.class, () -> authService.register(request));


    }

    @Test
    void loginSuccess() {
        LoginRequest request = new LoginRequest("testUsername", "testPassword");
        User user = new User();
        user.setUsername("testUsername");
        user.setEmail("test123@test.com");
        user.setPassword("testPassword");

        when(userRepository.findByUsername("testUsername")).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("testPassword", "testPassword")).thenReturn(true);
        when(jwtUtil.generateToken("test123@test.com")).thenReturn("FejkToken");

        AuthResponse result = authService.login(request);
        Assertions.assertNotNull(result);
        Assertions.assertEquals("FejkToken", result.getToken());
    }

    @Test
    void userNotFound() {
        LoginRequest request = new LoginRequest("testUsername", "testPassword");

        when(userRepository.findByUsername("testUsername")).thenReturn(Optional.empty());

        Assertions.assertThrows(RuntimeException.class, () -> authService.login(request));
    }

    @Test
    void wrongPassword() {
        LoginRequest request = new LoginRequest("testUsername", "wrongPassword");
        User user = new User();
        user.setUsername("testUsername");
        user.setPassword("testPassword");

        when(userRepository.findByUsername("testUsername")).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("wrongPassword", "testPassword")).thenReturn(false);

        Assertions.assertThrows(RuntimeException.class, () -> authService.login(request));

    }


}
