//Frontend "entre" :D
package com.winglog.user.controller;

import com.winglog.user.dto.request.UpdateProfileRequest;
import com.winglog.user.dto.response.UserProfileResponse;
import com.winglog.user.security.UserIdFilter;
import com.winglog.user.service.UserService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.UUID;

@RestController
@RequestMapping("/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }
    private UUID extractUserId(HttpServletRequest request) {
        String userId = (String) request.getAttribute(
                UserIdFilter.USER_ID_ATTRIBUTE
        );
        if (userId == null) {
            throw new RuntimeException(
                    "Ingen userId — saknas X-User-Id header från Gateway?"
            );
        }
        return UUID.fromString(userId);
    }

    @GetMapping("/me")
    public ResponseEntity<UserProfileResponse> getMyProfile(
            HttpServletRequest request
    ) {
        UUID userId = extractUserId(request);
        UserProfileResponse profile = userService.getMyProfile(userId);
        return ResponseEntity.ok(profile);
    }

    @PutMapping("/me")
    public ResponseEntity<UserProfileResponse> updateProfile(
            HttpServletRequest request,
            @Valid @RequestBody UpdateProfileRequest updateRequest
    ) {
        UUID userId = extractUserId(request);
        UserProfileResponse updated = userService.updateProfile(
                userId, updateRequest
        );
        return ResponseEntity.ok(updated);
    }

    @GetMapping("/{id}")
    public ResponseEntity<UserProfileResponse> getPublicProfile(
            @PathVariable UUID id
    ) {
        UserProfileResponse profile = userService.getPublicProfile(id);
        return ResponseEntity.ok(profile);
    }

    @DeleteMapping("/me")
    public ResponseEntity<Void> deleteAccount(
            HttpServletRequest request
    ) {
        UUID userId = extractUserId(request);
        userService.deleteAccount(userId);
        return ResponseEntity.noContent().build();
    }
}