package com.winglog.auth.controller;

import com.winglog.auth.dto.*;
import com.winglog.auth.service.AuthService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;



@RestController
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

    @PostMapping("/forgot-password")
    public ResponseEntity<String> forgotPassword(@RequestBody ForgotPasswordRequest request){
        authService.forgotPassword(request.getEmail());
        return ResponseEntity.ok("Email skickat!");
    }

    @PostMapping("/reset-password")
    public ResponseEntity<String> resetpassword(@RequestBody ResetPasswordRequest request){
        authService.resetPassword(request.getToken(), request.getNewPassword());
        return ResponseEntity.ok("Lösenord återställt");
    }

    @ExceptionHandler(RuntimeException.class)
    public ResponseEntity<String> handleException(RuntimeException e) {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(e.getMessage());
    }
}
