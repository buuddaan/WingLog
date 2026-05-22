package com.winglog.auth.controller;

import com.winglog.auth.config.TokenExchangeCache;
import com.winglog.auth.dto.*;
import com.winglog.auth.service.AuthService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

import java.util.Map;


@RestController
@RequestMapping("/auth")
public class AuthController {

    private final AuthService authService;
    private final TokenExchangeCache tokenExchangeCache; // /EF

    public AuthController(AuthService authService, TokenExchangeCache tokenExchangeCache) {
        this.authService = authService;
        this.tokenExchangeCache = tokenExchangeCache;
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

    /**
     * Engångsinlösen för OAuth Authorization Code-flöde.
     * Frontend skickar koden den fick i ?code=<uuid> efter Google-redirect
     * och får tillbaka JWT i response body istället för att JWT exponeras i URL. /EF
     *
     * @param body JSON med fältet "code"
     * @return JWT i fältet "token" om koden är giltig, 401 annars
     */
    @PostMapping("/exchange")
    public ResponseEntity<?> exchange(@RequestBody Map<String, String> body) {
        String code = body.get("code");
        String jwt = tokenExchangeCache.consume(code);

        if (jwt == null) {
            // Ogiltig, redan inlöst eller utgången kod /EF
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("error", "Ogiltig eller ugången code"));
        }

        return ResponseEntity.ok(Map.of("token", jwt));
    }

    @PostMapping("/forgot-password")
    public ResponseEntity<String> forgotPassword(@RequestBody ForgotPasswordRequest request) {
        authService.forgotPassword(request.getEmail());
        return ResponseEntity.ok("Email skickat!");
    }

    @PostMapping("/reset-password")
    public ResponseEntity<String> resetpassword(@RequestBody ResetPasswordRequest request) {
        authService.resetPassword(request.getToken(), request.getNewPassword());
        return ResponseEntity.ok("Lösenord återställt");
    }

    @ExceptionHandler(RuntimeException.class)
    public ResponseEntity<String> handleException(RuntimeException e) {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(e.getMessage());
    }
}
