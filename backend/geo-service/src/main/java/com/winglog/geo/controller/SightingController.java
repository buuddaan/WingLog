package com.winglog.geo.controller;

import com.winglog.geo.dto.SightingRequest;
import com.winglog.geo.dto.SightingResponse;
import com.winglog.geo.service.SightingService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/sightings")
public class SightingController {

    private final SightingService sightingService;

    public SightingController(SightingService sightingService) {
        this.sightingService = sightingService;
    }

    @PostMapping
    public ResponseEntity<?> createSighting(
            @RequestBody SightingRequest request,
            @RequestHeader("X-User-Id") UUID userId) { // userId skickas från gateway /EF
        if (request.getLatitude() == null) {
            return ResponseEntity.badRequest().body("Latitude is required and cannot be null");
        }
        if (request.getLongitude() == null) {
            return ResponseEntity.badRequest().body("Longitude is required and cannot be null");
        }
        if (request.getSpeciesName() == null || request.getSpeciesName().isBlank()) {
            return ResponseEntity.badRequest().body("Species name is required and cannot be null or blank");
        }
        return ResponseEntity.ok(sightingService.createSighting(request, userId));
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> updateSighting(
            @PathVariable UUID id,
            @RequestBody SightingRequest request,
            @RequestHeader("X-User-Id") UUID userId) {
        if (request.getLatitude() == null) {
            return ResponseEntity.badRequest().body("Latitude is required and cannot be null");
        }
        if (request.getLongitude() == null) {
            return ResponseEntity.badRequest().body("Longitude is required and cannot be null");
        }
        if (request.getSpeciesName() == null || request.getSpeciesName().isBlank()) {
            return ResponseEntity.badRequest().body("Species name is required and cannot be null or blank");
        }
        return ResponseEntity.ok(sightingService.updateSighting(id, request, userId));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteSighting(
            @PathVariable UUID id,
            @RequestHeader("X-User-Id") UUID userId) {
        sightingService.deleteSighting(id, userId);
        return ResponseEntity.noContent().build();
    }

    @GetMapping
    public ResponseEntity<List<SightingResponse>> getSightings(
            @RequestParam(required = false) String species) {
        if (species != null && !species.isBlank()) {
            return ResponseEntity.ok(sightingService.getSightingsBySpecies(species));
        }
        return ResponseEntity.ok(sightingService.getAllSightings());
    }

    @GetMapping("/{id}")
    public ResponseEntity<SightingResponse> getSightingById(@PathVariable UUID id) {
        return ResponseEntity.ok(sightingService.getSightingById(id));
    }
}