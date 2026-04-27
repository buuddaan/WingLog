package com.winglog.audio.controller;

import com.winglog.audio.model.AudioRecord;
import com.winglog.audio.service.AudioService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;

// Markerar att detta är ett REST API - svarar med JSON
@RestController
@CrossOrigin(origins = "*")
@RequestMapping("/audio")
public class AudioController {

    // Service används för att utföra logiken
    private final AudioService audioService;

    // Spring injicerar service automatiskt via constructor
    public AudioController(AudioService audioService) {
        this.audioService = audioService;
    }

    // POST /audio/identify
    // Tar emot en ljudfil och returnerar identifieringsresultatet
    @PostMapping("/identify")
    public ResponseEntity<AudioRecord> identify(@RequestParam("file") MultipartFile file) throws IOException {
        AudioRecord result = audioService.identify(file);
        return ResponseEntity.ok(result);
    }

    // GET /audio/history
    // Returnerar alla tidigare identifieringar från databasen
    @GetMapping("/history")
    public ResponseEntity<List<AudioRecord>> getHistory() {
        List<AudioRecord> history = audioService.getHistory();
        return ResponseEntity.ok(history);
    }
}
