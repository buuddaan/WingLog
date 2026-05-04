package com.winglog.photo.dto;

public class BirdCandidate {
    private String species;
    private Double confidence;

    public BirdCandidate(String species, Double confidence) {
        this.species = species;
        this.confidence = confidence;
    }

    public String getSpecies() {
        return species;
    }

    public Double getConfidence() {
        return confidence;
    }
}
