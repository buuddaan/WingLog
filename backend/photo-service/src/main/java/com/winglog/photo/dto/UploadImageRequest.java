package com.winglog.photo.dto;

import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDateTime;
import java.util.UUID;

public class UploadImageRequest {
    private final MultipartFile image;
    private final UUID sessionId;
    private final LocalDateTime date;
    private final Double longitude;
    private final Double latitude;

    public UploadImageRequest(MultipartFile image, UUID sessionId, LocalDateTime date, Double longitude, Double latitude){
        this.image = image;
        this.sessionId = sessionId;
        this.date = date;
        this.longitude = longitude;
        this.latitude = latitude;
    }

    public MultipartFile getImage(){
        return image;
    }

    public UUID getSessionId() {
        return sessionId;
    }

    public LocalDateTime getDate() {
        return date;
    }

    public Double getLongitude(){
        return longitude;
    }

    public Double getLatitude(){
        return latitude;
    }
}
