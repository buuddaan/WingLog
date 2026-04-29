package com.winglog.photo.dto;

import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDateTime;

public class UploadImageRequest {
    private final MultipartFile image;
    private final LocalDateTime date;
    private final Double longitude;
    private final Double latitude;

    public UploadImageRequest(MultipartFile image, LocalDateTime date, Double longitude, Double latitude){
        this.image = image;
        this.date = date;
        this.longitude = longitude;
        this.latitude = latitude;
    }

    public MultipartFile getImage(){
        return image;
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
