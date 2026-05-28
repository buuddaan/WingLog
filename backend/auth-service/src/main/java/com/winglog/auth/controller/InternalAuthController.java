package com.winglog.auth.controller;

import com.winglog.auth.service.AuthService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/internal")
public class InternalAuthController {
    private final AuthService authService;
    @Value("${INTERNAL_SECRET}")
    private String internalSecret;

    public InternalAuthController(AuthService authService) {
        this.authService = authService;
    }

    @DeleteMapping("/users/{userId}")
    public ResponseEntity<Void> deleteUser(@PathVariable("userId") UUID userId, @RequestHeader("X-Internal-Secret") String secret) {
        if(!internalSecret.equals(secret)){
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        authService.deleteUser(userId);
        return ResponseEntity.noContent().build();
    }

}
