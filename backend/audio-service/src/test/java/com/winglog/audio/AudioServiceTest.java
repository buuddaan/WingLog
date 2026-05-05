package com.winglog.audio;

import com.winglog.audio.model.AudioRecord;
import com.winglog.audio.model.IdentifyResponse;
import com.winglog.audio.repository.AudioRepository;
import com.winglog.audio.service.AudioService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class AudioServiceTest {

    @Mock
    private AudioRepository audioRepository;

    @Mock
    private RestTemplate restTemplate;

    @Mock
    private MultipartFile file;

    @InjectMocks
    private AudioService audioService;

    @Test
    void identify_validFile_returnsSavedRecord() throws IOException {
        when(file.getOriginalFilename()).thenReturn("kungsfagel.wav");
        when(file.getBytes()).thenReturn(new byte[]{1, 2, 3});
        when(restTemplate.postForObject(anyString(), any(), eq(Map.class)))
                .thenReturn(Map.of("suggestions", List.of(
                        Map.of("birdName", "Goldcrest", "scientificName", "Regulus regulus", "confidence", 0.88)
                )));

        AudioRecord saved = new AudioRecord();
        saved.setBirdName("Goldcrest");
        saved.setScientificName("Regulus regulus");
        saved.setConfidence(0.88);
        saved.setFileName("kungsfagel.wav");
        when(audioRepository.save(any(AudioRecord.class))).thenReturn(saved);

        IdentifyResponse result = audioService.identify(file);

        assertNotNull(result);
        assertEquals("Goldcrest", result.getSuggestions().get(0).getBirdName());
        assertEquals("Regulus regulus", result.getSuggestions().get(0).getScientificName());
        assertEquals(0.88, result.getSuggestions().get(0).getConfidence());
    }

    @Test
    void identify_setsCorrectFileName() throws IOException {
        when(file.getOriginalFilename()).thenReturn("svartstrupig.wav");
        when(file.getBytes()).thenReturn(new byte[]{1, 2, 3});
        when(restTemplate.postForObject(anyString(), any(), eq(Map.class)))
                .thenReturn(Map.of("suggestions", List.of(
                        Map.of("birdName", "Black-throated Sunbird", "scientificName", "Aethopyga saturata", "confidence", 0.99)
                )));

        AudioRecord saved = new AudioRecord();
        saved.setFileName("svartstrupig.wav");
        when(audioRepository.save(any(AudioRecord.class))).thenReturn(saved);

        IdentifyResponse result = audioService.identify(file);

        assertEquals("svartstrupig.wav", result.getSavedRecord().getFileName());
    }

    @Test
    void identify_birdnetNotResponding_throwsException() throws IOException {
        when(file.getBytes()).thenReturn(new byte[]{1, 2, 3});
        when(restTemplate.postForObject(anyString(), any(), eq(Map.class))).thenReturn(null);

        assertThrows(RuntimeException.class, () -> audioService.identify(file));
    }

    @Test
    void identify_fileReadFails_throwsIOException() throws IOException {
        when(file.getBytes()).thenThrow(new IOException("Kunde inte läsa filen"));

        assertThrows(IOException.class, () -> audioService.identify(file));
    }

    @Test
    void getHistory_returnsAllRecords() {
        AudioRecord record1 = new AudioRecord();
        record1.setBirdName("Goldcrest");

        AudioRecord record2 = new AudioRecord();
        record2.setBirdName("Black-throated Sunbird");

        when(audioRepository.findAll()).thenReturn(List.of(record1, record2));

        List<AudioRecord> result = audioService.getHistory();

        assertEquals(2, result.size());
        assertEquals("Goldcrest", result.get(0).getBirdName());
    }

    @Test
    void getHistory_returnsEmptyList() {
        when(audioRepository.findAll()).thenReturn(List.of());

        List<AudioRecord> result = audioService.getHistory();

        assertTrue(result.isEmpty());
    }
}
