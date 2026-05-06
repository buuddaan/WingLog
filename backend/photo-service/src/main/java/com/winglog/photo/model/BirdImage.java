package com.winglog.photo.model;

import jakarta.persistence.*;

import java.time.LocalDateTime;

import java.util.UUID;

@Entity
@Table(name = "bird_images")


public class BirdImage {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;
    @Column(nullable = false)
    private UUID userId;
    @Column(nullable = false, length = 500)
    private String imageUrl;
    @Column
    private String folderName;
    @Column(name = "session_id")
    private UUID sessionId;
    @Column(name = "taken_at")
    private LocalDateTime date;
    @Column
    private Double longitude;
    @Column
    private Double latitude;

    public BirdImage() {

    }

    public BirdImage(UUID id, UUID userId, String imageUrl, String folderName, UUID sessionId, LocalDateTime date, Double longitude, Double latitude) {
        this.id = id;
        this.userId = userId;
        this.imageUrl = imageUrl;
        this.folderName = folderName;
        this.sessionId = sessionId;
        this.date = date;
        this.longitude = longitude;
        this.latitude = latitude;
    }

    public UUID getId() {
        return id;
    }

    public UUID getUserId() {
        return userId;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public String getFolderName() {
        return folderName;
    }

    public void setFolderName(String folderName) {
        this.folderName = folderName;
    }

    public UUID getSessionId() {
        return sessionId;
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
