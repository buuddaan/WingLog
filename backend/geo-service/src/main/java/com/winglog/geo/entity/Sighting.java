package com.winglog.geo.entity;

import jakarta.persistence.*;
import org.locationtech.jts.geom.Point;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "sightings", schema = "geo_schema")
public class Sighting {

    @Id
    @Column(nullable = false, updatable = false)
    private UUID id; //Sätts av servern vid skapandet /EF

    @Column(name = "user_id", nullable = false, updatable = false)
    private UUID userId;

    @Column(name = "species_name", nullable = false)
    private String speciesName;

    @Column(columnDefinition = "geometry(Point,4326)", nullable = false)
    private Point location; //Hanteras av hibernate-spatial /EF

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt; //Sätts av servern /EF

    @Column(name = "updated_at")
    private LocalDateTime updatedAt; //Uppdateras vid varje ändring /EF

    @Column(name = "is_public", nullable = false)
    private boolean isPublic;

    @PrePersist
    protected void onCreate() {
        this.id = UUID.randomUUID();
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now(); //Sätts även vid skapandet /EF
    }

    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = LocalDateTime.now(); //Uppdateras automatiskt vid save /EF
    }

    public Sighting() {}

    public UUID getId() { return id; }
    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }
    public String getSpeciesName() { return speciesName; }
    public void setSpeciesName(String speciesName) { this.speciesName = speciesName; }
    public Point getLocation() { return location; }
    public void setLocation(Point location) { this.location = location; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public boolean isPublic() { return isPublic; }
    public void setPublic(boolean isPublic) { this.isPublic = isPublic; }
}