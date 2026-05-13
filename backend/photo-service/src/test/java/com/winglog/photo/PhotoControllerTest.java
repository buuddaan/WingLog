package com.winglog.photo;

import com.winglog.photo.controller.PhotoController;
import com.winglog.photo.dto.BirdCandidate;
import com.winglog.photo.dto.IdentifyResponse;
import com.winglog.photo.dto.ImageResponse;
import com.winglog.photo.dto.UploadImageRequest;
import com.winglog.photo.security.UserIdFilter;
import com.winglog.photo.service.PhotoService;
import jakarta.servlet.http.HttpServletRequest;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Mockito;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.ResponseEntity;
import org.springframework.web.multipart.MultipartFile;


import java.io.IOException;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
public class PhotoControllerTest {

    @Mock
    private PhotoService photoService;
    @Mock
    private MultipartFile file;
    @Mock
    private HttpServletRequest request;

    @InjectMocks
    private PhotoController photoController;

    @Test
    void uploadImageSuccess() throws IOException {
        UUID sessionId = UUID.randomUUID();
        UUID userId = UUID.randomUUID();
        LocalDateTime date = LocalDateTime.now();

        when(request.getAttribute(UserIdFilter.USER_ID_ATTRIBUTE)).thenReturn(userId.toString());
        when(photoService.uploadImage(Mockito.any(UploadImageRequest.class), Mockito.any(UUID.class))).thenReturn(new ImageResponse(UUID.randomUUID(), "https://fejk-url.com", "SångFågel", UUID.randomUUID(), LocalDateTime.now()));

        ResponseEntity<ImageResponse> result = photoController.uploadImage(request, file, sessionId, date);

        Assertions.assertNotNull(result);
        Assertions.assertEquals(200, result.getStatusCode().value());
    }

    @Test
    void identifyImage() throws IOException{
        BirdCandidate candidate = new BirdCandidate("Talgoxe", 100.00);
        List<BirdCandidate> candidateList =  new ArrayList<>();
        candidateList.add(candidate);

        when(photoService.identifyImage(file)).thenReturn(new IdentifyResponse(candidateList));

        ResponseEntity<IdentifyResponse> result = photoController.identifyImage(file);

        Assertions.assertNotNull(result);
        Assertions.assertEquals(200, result.getStatusCode().value());

    }

    @Test
    void saveToFolder() {
        UUID sessionId = UUID.randomUUID();
        UUID userId = UUID.randomUUID();
        String folderName = "Sångfågel";

        when(request.getAttribute(UserIdFilter.USER_ID_ATTRIBUTE)).thenReturn(userId.toString());

        ResponseEntity<Void> result = photoController.saveToFolder(request, sessionId, folderName);
        Assertions.assertNotNull(result);
        Assertions.assertEquals(200, result.getStatusCode().value());

    }

}
