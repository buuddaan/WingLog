package com.winglog.audio.model;

import java.util.List;

public class IdentifyResponse {
    private AudioRecord savedRecord;
    private List<BirdSuggestion> suggestions;

    public IdentifyResponse(AudioRecord savedRecord, List<BirdSuggestion> suggestions) {
        this.savedRecord = savedRecord;
        this.suggestions = suggestions;
    }

    public AudioRecord getSavedRecord() { return savedRecord; }
    public void setSavedRecord(AudioRecord savedRecord) { this.savedRecord = savedRecord; }

    public List<BirdSuggestion> getSuggestions() { return suggestions; }
    public void setSuggestions(List<BirdSuggestion> suggestions) { this.suggestions = suggestions; }
}
