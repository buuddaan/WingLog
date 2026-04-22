package com.winglog.auth;

import com.winglog.auth.controller.AuthController;
import com.winglog.auth.dto.AuthResponse;
import com.winglog.auth.dto.LoginRequest;
import com.winglog.auth.dto.RegisterRequest;
import com.winglog.auth.service.AuthService;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
public class AuthControllerTest {

    @Mock
    private AuthService authService;

    @InjectMocks
    private AuthController authController;

    @Test
    void registerSuccess() {

        RegisterRequest request = new RegisterRequest("test123@test.com", "testUsername", "testPassword");

        when(authService.register(request)).thenReturn(new AuthResponse("FejkToken"));

        AuthResponse result = authController.register(request);

        Assertions.assertNotNull(result);
        Assertions.assertEquals("FejkToken", result.getToken());
    }

    @Test
    void loginSuccess(){

        LoginRequest request = new LoginRequest("testUsername", "testPassword");

        when(authService.login(request)).thenReturn(new AuthResponse("FejkToken"));

        AuthResponse result = authController.login(request);

        Assertions.assertNotNull(result);
        Assertions.assertEquals("FejkToken", result.getToken());

    }




}
