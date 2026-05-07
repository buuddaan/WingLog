package com.winglog.geo.repository;

import com.winglog.geo.entity.Sighting;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.UUID;

public interface SightingRepository extends JpaRepository<Sighting, UUID> {

    List<Sighting> findBySpeciesNameIgnoreCase(String speciesName);

    @Modifying
    @Query("DELETE FROM Sighting s WHERE s.id = :id")
    void deleteByEntityId(@Param("id") UUID id);
}