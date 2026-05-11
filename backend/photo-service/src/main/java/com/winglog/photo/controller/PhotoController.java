package com.winglog.photo.controller;


import com.winglog.photo.dto.IdentifyResponse;
import com.winglog.photo.dto.ImageResponse;
import com.winglog.photo.dto.UploadImageRequest;
import com.winglog.photo.security.UserIdFilter;
import com.winglog.photo.service.PhotoService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.UUID;

import static com.cloudinary.AccessControlRule.AccessType.token;

@RestController
@RequestMapping("/photos")
public class PhotoController {

    private PhotoService photoService;

    public PhotoController(PhotoService photoService){
        this.photoService = photoService;
    }

    @PostMapping("/upload")
    public ResponseEntity<ImageResponse> uploadImage(
            HttpServletRequest request,
            @RequestParam MultipartFile file,
            @RequestParam UUID sessionId,
            @RequestParam LocalDateTime date,
            @RequestParam Double longitude,
            @RequestParam Double latitude) throws IOException{
        UUID userId = UUID.fromString((String) request.getAttribute(UserIdFilter.USER_ID_ATTRIBUTE));
        UploadImageRequest uploadRequest = new UploadImageRequest(file, sessionId, date, longitude, latitude);
        return ResponseEntity.ok(photoService.uploadImage(uploadRequest, userId));
    }

    @PostMapping("/identify")
    public ResponseEntity<IdentifyResponse> identifyImage(
            @RequestParam MultipartFile file
    ) throws  IOException{
        return ResponseEntity.ok(photoService.identifyImage(file));
    }
    @PutMapping("/save-to-folder")
    public ResponseEntity<Void> saveToFolder(
            HttpServletRequest request,
            @RequestParam UUID sessionId,
            @RequestParam String folderName) {

        UUID userId = UUID.fromString((String) request.getAttribute(UserIdFilter.USER_ID_ATTRIBUTE));
        photoService.saveToFolder(sessionId, userId, folderName);
        return ResponseEntity.ok().build();
    }

    @PutMapping("/save-unidentified")
    public ResponseEntity<Void> saveAsUnidentified(
            HttpServletRequest request,
            @RequestParam UUID sessionId) {
        UUID userId = UUID.fromString((String) request.getAttribute(UserIdFilter.USER_ID_ATTRIBUTE));
        photoService.saveAsUnidentified(sessionId, userId);
        return ResponseEntity.ok().build();

    }
    @DeleteMapping("/delete-session")
    public ResponseEntity<Void> deleteSession(
            HttpServletRequest request,
            @RequestParam UUID sessionId){

       UUID userId = UUID.fromString((String) request.getAttribute(UserIdFilter.USER_ID_ATTRIBUTE));
       photoService.deleteSession(sessionId,userId);
       return ResponseEntity.noContent().build();

    }

}
