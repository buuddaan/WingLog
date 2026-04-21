package com.winglog.user.model;

import jakarta.persistence.*; //Bra på att omvandla JSON/XML till java-klasser
import java.time.LocalDateTime;
import java.util.UUID;

//Talar om att det är en databastabell
@Entity
@Table(name = "user_profiles")

public class UserProfile {

    @Id
    @Column(name = "user_id", nullable = false, updatable = false)
    private UUID userId; //Sätts av auth_service vid skapandet (gör ingen setter pga bör ej kunna ändras)

    @Column(name = "display_name", nullable = false, length = 100) //För varje anv måste ha ett anv-namn i tex forum
    private String displayName;

    @Column(name = "bio", columnDefinition = "TEXT") //Frivillig?
    private String bio;

    @Column(name = "profile_photo_url", length = 500) //URL till profilbild fr Cloudflare R2 (via media-service)? Ska kunna = null
    private String profilePhotoUrl;

    @Column(name = "created_at", nullable = false, updatable = false) //Automatisk tidsstämpel när man skapa profilen
    private LocalDateTime createdAt;
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    //Körs automatiskt av JPA precis innan objektet sparas första gången
    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
    }
    //Körs automatiskt av JPA varje gång objektet uppdateras
    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }

    public UserProfile() {} //Krävs av JPA för att kunna skapa obj från db-rader

    public UserProfile(UUID userId, String displayName) {
        this.userId = userId;
        this.displayName = displayName;
        //bio och profilePhotoUrl = null automatiskt, kan sättas senare? /EF
    }

    public UUID getUserId() { return userId; }
    public String getDisplayName() { return displayName; }
    public void setDisplayName(String displayName) { this.displayName = displayName; }
    public String getBio() { return bio; }
    public void setBio(String bio) { this.bio = bio; }

    public String getProfilePhotoUrl() { return profilePhotoUrl; }
    public void setProfilePhotoUrl(String profilePhotoUrl) { this.profilePhotoUrl = profilePhotoUrl; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}