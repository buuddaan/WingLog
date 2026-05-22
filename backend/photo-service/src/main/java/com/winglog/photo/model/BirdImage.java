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
    @Column
    private String publicId;
    @Column(nullable = false, length = 500)
    private String imageUrl;
    @Column
    private String folderName;
    @Column(name = "session_id")
    private UUID sessionId;
    @Column(name = "taken_at")
    private LocalDateTime date;

    public BirdImage() {

    }

    public BirdImage(UUID userId, String publicId , String imageUrl, String folderName, UUID sessionId, LocalDateTime date) {
        this.userId = userId;
        this.publicId = publicId;
        this.imageUrl = imageUrl;
        this.folderName = folderName;
        this.sessionId = sessionId;
        this.date = date;
    }

    public UUID getId() {
        return id;
    }

    public UUID getUserId() {
        return userId;
    }

    public String getPublicId() {
        return publicId;
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

}
