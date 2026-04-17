package com.winglog.audio.repository;

import com.winglog.audio.model.AudioRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.UUID;

// Markerar att detta är ett repository (databaslager)
@Repository
// Ärver JpaRepository - Spring genererar automatiskt save(), findAll(), deleteById() etc.
// AudioRecord = tabellen vi jobbar med, UUID = typ på id-kolumnen
public interface AudioRepository extends JpaRepository<AudioRecord, UUID> {

}
