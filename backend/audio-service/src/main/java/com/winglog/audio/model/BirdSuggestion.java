package com.winglog.audio.model;

public class BirdSuggestion {
    private String birdName;
    private String scientificName;
    private double confidence;

    public BirdSuggestion() {}

    public BirdSuggestion(String birdName, String scientificName, double confidence) {
        this.birdName = birdName;
        this.scientificName = scientificName;
        this.confidence = confidence;
    }

    public String getBirdName() { return birdName; }
    public void setBirdName(String birdName) { this.birdName = birdName; }

    public String getScientificName() { return scientificName; }
    public void setScientificName(String scientificName) { this.scientificName = scientificName; }

    public double getConfidence() { return confidence; }
    public void setConfidence(double confidence) { this.confidence = confidence; }
}
