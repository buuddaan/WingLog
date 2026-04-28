package com.winglog.geo.repository;

import com.winglog.geo.entity.Sighting;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface SightingRepository extends JpaRepository<Sighting, UUID> {

    List<Sighting> findBySpeciesNameIgnoreCase(String speciesName);
}