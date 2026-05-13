package com.winglog.photo;


import com.winglog.photo.dto.ImageResponse;
import com.winglog.photo.dto.UploadImageRequest;
import com.winglog.photo.model.BirdImage;
import com.winglog.photo.repository.BirdImageRepository;
import com.winglog.photo.service.PhotoService;
import com.winglog.photo.service.StorageService;
import com.winglog.photo.service.VisionService;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Mockito;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
public class PhotoServiceTest {
    @Mock
    private StorageService storageService;
    @Mock
    private VisionService visionService;
    @Mock
    BirdImageRepository birdImageRepository;
    @Mock
    MultipartFile file;

    @InjectMocks
    PhotoService photoService;

    @Test
    void uploadImageSuccess() throws IOException {
        UploadImageRequest uploadImageRequest = new UploadImageRequest(file, UUID.randomUUID(), LocalDateTime.now() );
        when(storageService.uploadImage(file)).thenReturn("https://fejkimage-url.com");

        UUID userId = UUID.randomUUID();
        ImageResponse result =  photoService.uploadImage(uploadImageRequest, userId);
        Assertions.assertNotNull(result);
        Assertions.assertEquals("https://fejkimage-url.com", result.getImageUrl());
    }

    @Test
    void saveToFolderSuccess(){
        UUID sessionId = UUID.randomUUID();
        UUID userId = UUID.randomUUID();
        List<BirdImage> Images = new ArrayList<>();
        Images.add(new BirdImage(userId, "https://fejkimage-url.com", null, sessionId, LocalDateTime.now()));
        Images.add(new BirdImage(userId, "https://halla-url.com", null, sessionId, LocalDateTime.now()));

        when(birdImageRepository.findBySessionIdAndUserId(sessionId, userId)).thenReturn(Images);

        photoService.saveToFolder(sessionId, userId, "Sångfågel");

        ArgumentCaptor<BirdImage> captor = ArgumentCaptor.forClass(BirdImage.class);
        Mockito.verify(birdImageRepository, Mockito.times(2)).save(captor.capture());
        captor.getAllValues().forEach(image ->
                Assertions.assertEquals("Sångfågel", image.getFolderName()));


    }

    @Test
    void saveAsUnidentifiedSuccess(){
        UUID sessionId = UUID.randomUUID();
        UUID userId = UUID.randomUUID();
        List<BirdImage> existingImages = new ArrayList<>();
        existingImages.add(new BirdImage(userId, "https://fejkimage-url.com", "Oidentifierade", sessionId, LocalDateTime.now()));

        List<BirdImage> sessionImages = new ArrayList<>();
        sessionImages.add(new BirdImage(userId, "https://halla-url.com", null, sessionId, LocalDateTime.now()));

        when(birdImageRepository.findByUserIdAndFolderNameStartingWith(userId, "Oidentifierade")).thenReturn(existingImages);
        when(birdImageRepository.findBySessionIdAndUserId(sessionId, userId)).thenReturn(sessionImages);

        photoService.saveAsUnidentified(sessionId, userId);

        ArgumentCaptor<BirdImage> captor = ArgumentCaptor.forClass(BirdImage.class);
        Mockito.verify(birdImageRepository, Mockito.times(1)).save(captor.capture());
        Assertions.assertEquals("Oidentifierade2", captor.getValue().getFolderName());
    }

    @Test
    void deleteSessionSuccess(){
        UUID sessionId = UUID.randomUUID();
        UUID userId = UUID.randomUUID();

        photoService.deleteSession(sessionId, userId);
        Mockito.verify(birdImageRepository).deleteBySessionIdAndUserId(sessionId, userId);
    }
}
