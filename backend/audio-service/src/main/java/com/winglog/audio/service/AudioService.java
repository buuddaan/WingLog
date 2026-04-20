package com.winglog.audio.service;

import com.winglog.audio.model.AudioRecord;
import com.winglog.audio.repository.AudioRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;
import java.util.Map;

@Service
public class AudioService {

    private final AudioRepository audioRepository;
    private final RestTemplate restTemplate = new RestTemplate();

    @Value("${birdnet.url}")
    private String birdnetUrl;

    public AudioService(AudioRepository audioRepository) {
        this.audioRepository = audioRepository;
    }

    public AudioRecord identify(MultipartFile file) throws IOException {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.MULTIPART_FORM_DATA);

        MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
        body.add("file", new ByteArrayResource(file.getBytes()) {
            @Override
            public String getFilename() {
                return file.getOriginalFilename();
            }
        });

        HttpEntity<MultiValueMap<String, Object>> request = new HttpEntity<>(body, headers);
        Map<String, Object> response = restTemplate.postForObject(birdnetUrl + "/analyze", request, Map.class);

        AudioRecord record = new AudioRecord();
        record.setFileName(file.getOriginalFilename());
        record.setBirdName((String) response.get("birdName"));
        record.setScientificName((String) response.get("scientificName"));
        record.setConfidence(((Number) response.get("confidence")).doubleValue());

        return audioRepository.save(record);
    }

    public List<AudioRecord> getHistory() {
        return audioRepository.findAll();
    }
}
