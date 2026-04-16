package com.winglog.audio.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "audio_records")
public class AudioRecord {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "bird_name")
    private String birdName;

    @Column(name = "scientific_name")
    private String scientificName;

    @Column(name = "confidence")
    private Double confidence;

    @Column(name = "file_name")
    private String fileName;

    @Column(name = "identified_at")
    private LocalDateTime identifiedAt = LocalDateTime.now();

    public AudioRecord() {}

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public String getBirdName() { return birdName; }
    public void setBirdName(String birdName) { this.birdName = birdName; }

    public String getScientificName() { return scientificName; }
    public void setScientificName(String scientificName) { this.scientificName = scientificName; }

    public Double getConfidence() { return confidence; }
    public void setConfidence(Double confidence) { this.confidence = confidence; }

    public String getFileName() { return fileName; }
    public void setFileName(String fileName) { this.fileName = fileName; }

    public LocalDateTime getIdentifiedAt() { return identifiedAt; }
    public void setIdentifiedAt(LocalDateTime identifiedAt) { this.identifiedAt = identifiedAt; }
}
