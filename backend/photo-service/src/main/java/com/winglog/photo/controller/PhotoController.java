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
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/photos")
public class PhotoController {

    private PhotoService photoService;

    public PhotoController(PhotoService photoService) {
        this.photoService = photoService;
    }

    @PostMapping("/upload")
    public ResponseEntity<ImageResponse> uploadImage(
            HttpServletRequest request,
            @RequestParam("file") MultipartFile file,
            @RequestParam("sessionId") UUID sessionId,
            @RequestParam("date") @org.springframework.format.annotation.DateTimeFormat(iso = org.springframework.format.annotation.DateTimeFormat.ISO.DATE_TIME) LocalDateTime date) throws IOException {

        UUID userId = UUID.fromString((String) request.getAttribute(UserIdFilter.USER_ID_ATTRIBUTE));
        UploadImageRequest uploadRequest = new UploadImageRequest(file, sessionId, date);
        return ResponseEntity.ok(photoService.uploadImage(uploadRequest, userId));
    }

    /** Från Axel**/
    @GetMapping("/my-photos")
    public ResponseEntity<List<ImageResponse>> getMyPhotos(HttpServletRequest request) {
        UUID userId = UUID.fromString((String) request.getAttribute(UserIdFilter.USER_ID_ATTRIBUTE));
        return ResponseEntity.ok(photoService.getMyPhotos(userId));
    }

    @PostMapping("/identify")
    public ResponseEntity<IdentifyResponse> identifyImage(
            @RequestParam("file") MultipartFile file
    ) throws IOException {
        return ResponseEntity.ok(photoService.identifyImage(file));
    }

    @PutMapping("/save-to-folder")
    public ResponseEntity<Void> saveToFolder(
            HttpServletRequest request,
            @RequestParam("sessionId") UUID sessionId,
            @RequestParam("folderName") String folderName) {

        UUID userId = UUID.fromString((String) request.getAttribute(UserIdFilter.USER_ID_ATTRIBUTE));
        photoService.saveToFolder(sessionId, userId, folderName);
        return ResponseEntity.ok().build();
    }

    @PutMapping("/save-unidentified")
    public ResponseEntity<Void> saveAsUnidentified(
            HttpServletRequest request,
            @RequestParam("sessionId") UUID sessionId) {
        UUID userId = UUID.fromString((String) request.getAttribute(UserIdFilter.USER_ID_ATTRIBUTE));
        photoService.saveAsUnidentified(sessionId, userId);
        return ResponseEntity.ok().build();
    }

    @DeleteMapping("/delete-session")
    public ResponseEntity<Void> deleteSession(
            HttpServletRequest request,
            @RequestParam("sessionId") UUID sessionId) {

        UUID userId = UUID.fromString((String) request.getAttribute(UserIdFilter.USER_ID_ATTRIBUTE));
        photoService.deleteSession(sessionId, userId);
        return ResponseEntity.noContent().build();
    }

    @DeleteMapping("/delete-image")
    public ResponseEntity<Void> deleteImage(
            HttpServletRequest request,
            @RequestParam("imageId") UUID imageId) throws  IOException{

        UUID userId = UUID.fromString((String) request.getAttribute(UserIdFilter.USER_ID_ATTRIBUTE));
        photoService.deleteImage(imageId, userId);
        return ResponseEntity.noContent().build();
    }

    @PutMapping("/rename-folder")
    public ResponseEntity<Void> renameFolder(
            HttpServletRequest request,
            @RequestParam("oldName") String oldName,
            @RequestParam("newName") String newName) {

        UUID userId = UUID.fromString((String) request.getAttribute(UserIdFilter.USER_ID_ATTRIBUTE));
        photoService.renameFolder(oldName, newName, userId);
        return ResponseEntity.ok().build();
    }

    @DeleteMapping("/delete-folder")
    public ResponseEntity<Void> deleteFolder(
            HttpServletRequest request,
            @RequestParam("folderName") String folderName) {

        UUID userId = UUID.fromString((String) request.getAttribute(UserIdFilter.USER_ID_ATTRIBUTE));
        photoService.deleteFolder(folderName, userId);
        return ResponseEntity.noContent().build();
    }

}
