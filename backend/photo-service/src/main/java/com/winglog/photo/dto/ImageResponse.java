package com.winglog.photo.dto;

import java.time.LocalDateTime;
import java.util.UUID;

public class ImageResponse {

    private UUID id;
    private String imageUrl;
    private String folderName;
    private LocalDateTime date;
    private Double longitude;
    private Double latitude;

    public ImageResponse(UUID id, String imageUrl, String folderName, LocalDateTime date, Double longitude, Double latitude) {
        this.id = id;
        this.imageUrl = imageUrl;
        this.folderName = folderName;
        this.date = date;
        this.longitude = longitude;
        this.latitude = latitude;
    }

    public UUID getId() {
        return id;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public String getFolderName() {
        return folderName;
    }

    public LocalDateTime getDate() {
        return date;
    }

    public Double getLongitude() {
        return longitude;
    }

    public Double getLatitude() {
        return latitude;
    }
}
