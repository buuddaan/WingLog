package com.winglog.photo.dto;

import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDateTime;
import java.util.UUID;

public class UploadImageRequest {
    private final MultipartFile image;
    private final UUID sessionId;
    private final LocalDateTime date;

    public UploadImageRequest(MultipartFile image, UUID sessionId, LocalDateTime date) {
        this.image = image;
        this.sessionId = sessionId;
        this.date = date;

    }

    public MultipartFile getImage() {
        return image;
    }

    public UUID getSessionId() {
        return sessionId;
    }

    public LocalDateTime getDate() {
        return date;
    }

}
