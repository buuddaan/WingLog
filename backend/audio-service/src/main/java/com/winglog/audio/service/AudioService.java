package com.winglog.audio.service;

import com.winglog.audio.model.AudioRecord;
import com.winglog.audio.repository.AudioRepository;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import java.util.List;

// Markerar att detta är service-lagret - all logik finns här
@Service
public class AudioService {

    // Repository används för att kommunicera med databasen
    private final AudioRepository audioRepository;

    // Spring injicerar repository automatiskt via constructor
    public AudioService(AudioRepository audioRepository) {
        this.audioRepository = audioRepository;
    }

    // Tar emot en ljudfil, identifierar fågeln och sparar resultatet i databasen
    public AudioRecord identify(MultipartFile file) {

        // Skapar ett nytt AudioRecord-objekt som ska sparas
        AudioRecord record = new AudioRecord();

        // Sätter filnamnet från den uppladdade filen
        record.setFileName(file.getOriginalFilename());

        // Mock - hårdkodat svar istället för riktigt BirdNET-anrop
        record.setBirdName("Koltrast");
        record.setScientificName("Turdus merula");
        record.setConfidence(0.94);

        // Sparar i databasen och returnerar det sparade objektet
        return audioRepository.save(record);
    }

    // Hämtar alla tidigare identifieringar från databasen
    public List<AudioRecord> getHistory() {
        return audioRepository.findAll();
    }
}
