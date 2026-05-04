package com.winglog.photo.dto;

import java.util.List;

public class IdentifyResponse {
    private List<BirdCandidate> candidates;

    public IdentifyResponse(List<BirdCandidate> candidates) {
        this.candidates = candidates;

    }

    public List<BirdCandidate> getCandidates() {
        return candidates;
    }
}
