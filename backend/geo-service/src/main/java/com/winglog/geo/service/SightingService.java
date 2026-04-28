package com.winglog.geo.service;

import com.winglog.geo.dto.SightingRequest;
import com.winglog.geo.dto.SightingResponse;
import com.winglog.geo.entity.Sighting;
import com.winglog.geo.repository.SightingRepository;
import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.Point;
import org.locationtech.jts.geom.PrecisionModel;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
public class SightingService {

    private final SightingRepository sightingRepository;
    private final GeometryFactory geometryFactory = new GeometryFactory(new PrecisionModel(), 4326); //SRID 4326 = WGS84 /EF

    public SightingService(SightingRepository sightingRepository) {
        this.sightingRepository = sightingRepository;
    }

    public SightingResponse createSighting(SightingRequest request, UUID userId) {
        Point location = geometryFactory.createPoint(new Coordinate(request.getLongitude(), request.getLatitude()));

        Sighting sighting = new Sighting();
        sighting.setUserId(userId);
        sighting.setSpeciesName(request.getSpeciesName());
        sighting.setLocation(location);
        sighting.setDescription(request.getDescription());
        sighting.setPublic(request.isPublic());

        return SightingResponse.fromEntity(sightingRepository.save(sighting));
    }

    public List<SightingResponse> getAllSightings() {
        return sightingRepository.findAll().stream()
                .map(SightingResponse::fromEntity)
                .toList();
    }

    public List<SightingResponse> getSightingsBySpecies(String speciesName) {
        return sightingRepository.findBySpeciesNameIgnoreCase(speciesName).stream()
                .map(SightingResponse::fromEntity)
                .toList();
    }

    public SightingResponse getSightingById(UUID id) {
        Sighting sighting = sightingRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Sighting not found: " + id)); //Kan bytas mot custom exception senare /EF
        return SightingResponse.fromEntity(sighting);
    }

    public void deleteSighting(UUID id, UUID userId) {
        Sighting sighting = sightingRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Sighting not found: " + id)); //Kan bytas mot custom exception senare /EF
        if (!sighting.getUserId().equals(userId)) { //Kontrollera att användaren äger observationen /EF
            throw new RuntimeException("Not authorized to delete this sighting");
        }
        sightingRepository.delete(sighting); //Ta bort observationen från databasen /EF
    }

    public SightingResponse updateSighting(UUID id, SightingRequest request, UUID userId) {
        Sighting sighting = sightingRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Sighting not found: " + id)); //Kan bytas mot custom exception senare /EF
        if (!sighting.getUserId().equals(userId)) { //Kontrollera att användaren äger observationen /EF
            throw new RuntimeException("Not authorized to update this sighting");
        }
        sighting.setSpeciesName(request.getSpeciesName()); //Uppdatera artnamn /EF
        Point location = geometryFactory.createPoint(new Coordinate(request.getLongitude(), request.getLatitude())); //Bygg ny plats från koordinater /EF
        sighting.setLocation(location);
        sighting.setDescription(request.getDescription()); //Uppdatera beskrivning /EF
        sighting.setPublic(request.isPublic()); //Uppdatera synlighet /EF
        return SightingResponse.fromEntity(sightingRepository.save(sighting)); //Spara och returnera uppdaterad observation /EF
    }
}