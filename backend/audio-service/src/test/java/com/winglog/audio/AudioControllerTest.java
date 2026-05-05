package com.winglog.audio;

import com.winglog.audio.controller.AudioController;
import com.winglog.audio.model.AudioRecord;
import com.winglog.audio.model.BirdSuggestion;
import com.winglog.audio.model.IdentifyResponse;
import com.winglog.audio.service.AudioService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.ResponseEntity;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class AudioControllerTest {

    @Mock
    private AudioService audioService;

    @Mock
    private MultipartFile file;

    @InjectMocks
    private AudioController audioController;

    @Test
    void identify_returnsOkWithRecord() throws IOException {
        AudioRecord record = new AudioRecord();
        record.setBirdName("Goldcrest");
        record.setScientificName("Regulus regulus");
        record.setConfidence(0.88);
        List<BirdSuggestion> suggestions = List.of(new BirdSuggestion("Goldcrest", "Regulus regulus", 0.88));
        IdentifyResponse identifyResponse = new IdentifyResponse(record, suggestions);

        when(audioService.identify(file)).thenReturn(identifyResponse);

        ResponseEntity<IdentifyResponse> response = audioController.identify(file);

        assertEquals(200, response.getStatusCode().value());
        assertNotNull(response.getBody());
        assertEquals("Goldcrest", response.getBody().getSuggestions().get(0).getBirdName());
    }

    @Test
    void getHistory_returnsOkWithList() {
        AudioRecord record1 = new AudioRecord();
        record1.setBirdName("Goldcrest");

        AudioRecord record2 = new AudioRecord();
        record2.setBirdName("Black-throated Sunbird");

        when(audioService.getHistory()).thenReturn(List.of(record1, record2));

        ResponseEntity<List<AudioRecord>> response = audioController.getHistory();

        assertEquals(200, response.getStatusCode().value());
        assertEquals(2, response.getBody().size());
    }

    @Test
    void getHistory_returnsOkWithEmptyList() {
        when(audioService.getHistory()).thenReturn(List.of());

        ResponseEntity<List<AudioRecord>> response = audioController.getHistory();

        assertEquals(200, response.getStatusCode().value());
        assertTrue(response.getBody().isEmpty());
    }
}
