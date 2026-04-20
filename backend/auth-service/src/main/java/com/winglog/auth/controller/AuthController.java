package com.winglog.auth.controller;

import com.winglog.auth.dto.AuthResponse;
import com.winglog.auth.dto.LoginRequest;
import com.winglog.auth.dto.RegisterRequest;
import com.winglog.auth.service.AuthService;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController //berättar för spring att detta tar emot HTTP anrop svaren ska skickas tillbacka som JSON
@RequestMapping("/auth")
public class AuthController {
    private AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;

    }

    /**
     * Hanterar en registeringsförfrågan
     *
     * @param request innehållandes email, användarnamn och lösenord på en ny användare
     * @return AuthResonse innehållande JWT-token för autentisering
     */
    @PostMapping("/register")
    public AuthResponse register(@RequestBody RegisterRequest request) {

        return authService.register(request);
    }

    /**
     * Hanterar en inloggningsförfrågan
     *
     * @param request innehållande användarens användarnamn och lösenord
     * @return AuthResponse innehållande JWT-Token för autentisering
     */
    @PostMapping("/login")
    public AuthResponse login(@RequestBody LoginRequest request) {
        return authService.login(request);
    }


}
