//Auth_service entre :D

package com.winglog.user.controller;

import com.winglog.user.dto.CreateProfileRequest;
import com.winglog.user.dto.UserProfileResponse;
import com.winglog.user.service.UserService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/internal")
public class InternalUserController {
    private final UserService userService;

    public InternalUserController(UserService userService) {
        this.userService = userService;
    }

    @PostMapping("/profiles")
    public ResponseEntity<UserProfileResponse> createProfile(
            @Valid @RequestBody CreateProfileRequest request
    ) {
        UserProfileResponse created = userService.createProfile(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }
}