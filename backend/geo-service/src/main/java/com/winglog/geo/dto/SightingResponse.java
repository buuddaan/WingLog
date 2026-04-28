package com.winglog.geo.dto;

import com.winglog.geo.entity.Sighting;

import java.time.LocalDateTime;
import java.util.UUID;

public class SightingResponse {

    private UUID id;
    private UUID userId;
    private String speciesName;
    private double latitude;  //Extraheras ur Point /EF
    private double longitude; //Extraheras ur Point /EF
    private String description;
    private LocalDateTime createdAt;
    private boolean isPublic;

    public SightingResponse() {}

    public SightingResponse(UUID id, UUID userId, String speciesName,
                            double latitude, double longitude,
                            String description, LocalDateTime createdAt, boolean isPublic) {
        this.id = id;
        this.userId = userId;
        this.speciesName = speciesName;
        this.latitude = latitude;
        this.longitude = longitude;
        this.description = description;
        this.createdAt = createdAt;
        this.isPublic = isPublic;
    }

    public static SightingResponse fromEntity(Sighting sighting) {
        return new SightingResponse(
                sighting.getId(),
                sighting.getUserId(),
                sighting.getSpeciesName(),
                sighting.getLocation().getY(), //Y = latitude /EF
                sighting.getLocation().getX(), //X = longitude /EF
                sighting.getDescription(),
                sighting.getCreatedAt(),
                sighting.isPublic()
        );
    }

    public UUID getId() { return id; }
    public UUID getUserId() { return userId; }
    public String getSpeciesName() { return speciesName; }
    public double getLatitude() { return latitude; }
    public double getLongitude() { return longitude; }
    public String getDescription() { return description; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public boolean isPublic() { return isPublic; }
}