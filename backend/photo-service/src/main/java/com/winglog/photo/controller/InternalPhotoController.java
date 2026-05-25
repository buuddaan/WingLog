package com.winglog.photo.controller;


import com.winglog.photo.service.PhotoService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;
import java.util.UUID;

@RestController
@RequestMapping("/internal")
public class InternalPhotoController {
    private final PhotoService photoService;

    @Value("${internal.secret}")
    private String internalSecret;

    public InternalPhotoController(PhotoService photoService) {
        this.photoService = photoService;
    }

    @DeleteMapping("/photos/{userId}")
    public ResponseEntity<Void> deleteAllByUserId(
            @PathVariable UUID userId, @RequestHeader("X-Internal-Secret") String secret) throws IOException {
        if (!internalSecret.equals(secret)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }

        photoService.deleteAllByUserId(userId);
        return ResponseEntity.noContent().build();
    }

}
