package com.winglog.photo.service;

import com.winglog.photo.dto.IdentifyResponse;
import com.winglog.photo.dto.ImageResponse;
import com.winglog.photo.dto.UploadImageRequest;
import com.winglog.photo.model.BirdImage;
import com.winglog.photo.repository.BirdImageRepository;
import jakarta.transaction.Transactional;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

@Service
public class PhotoService {
    private StorageService storageService;
    private VisionService visionService;
    private BirdImageRepository birdImageRepository;

    public PhotoService(StorageService storageService, VisionService visionService, BirdImageRepository birdImageRepository) {
        this.storageService = storageService;
        this.visionService = visionService;
        this.birdImageRepository = birdImageRepository;
    }

    /**
     * Laddar upp bild till Cloudinary, sparar bildinformation i databasen.
     *
     * @param request som innehåller bildfilen, session id datum och koordinater
     * @param userId  användarens id
     * @return ImageResponse innehållande bildens information
     * @throws IOException om inte bilden kan läsas in
     */
    public ImageResponse uploadImage(UploadImageRequest request, UUID userId) throws IOException {
        String[] uploadResult = storageService.uploadImage(request.getImage());
        String imageUrl = uploadResult[0];
        String publicId = uploadResult[1];
        BirdImage birdImage = new BirdImage(userId, publicId, imageUrl, null, request.getSessionId(), request.getDate());
        birdImageRepository.save(birdImage);

        return new ImageResponse(birdImage.getId(), birdImage.getImageUrl(), birdImage.getFolderName(), birdImage.getSessionId(), birdImage.getDate());
    }

    /**
     * Identifierar fågelarten på bilden med Google Cloud Vision API.
     *
     * @param image bilden som ska identifieras
     * @return IdentifyResponse innehållande en lista av möjliga fågelarter och hur stor sannolikheten är att det är den arten.
     * @throws IOException om bilden inte kan läsas
     */
    public IdentifyResponse identifyImage(MultipartFile image) throws IOException {
        return visionService.identifyBirdImage(image);

    }

    /**
     * Sparar alla bilder från en session i en namngiven mapp
     *
     * @param sessionId  sessionens id
     * @param userId     användarens id
     * @param folderName mappnamnet
     */
    public void saveToFolder(UUID sessionId, UUID userId, String folderName) {
        List<BirdImage> images = birdImageRepository.findBySessionIdAndUserId(sessionId, userId);

        for (BirdImage image : images) {
            image.setFolderName(folderName);
            birdImageRepository.save(image);
        }
    }
    /** Från Axel **/
    public List<ImageResponse> getMyPhotos(UUID userId) {
        List<BirdImage> images = birdImageRepository.findByUserId(userId);
        return images.stream()
                .map(img -> new ImageResponse(img.getId(), img.getImageUrl(), img.getFolderName(), img.getSessionId(), img.getDate()))
                .toList();
    }
    /**
     * Sparar alla bilder får en session i en oidentifierad mapp.
     * Mappnamn genereras automatiskt
     *
     * @param sessionId sessionens id
     * @param userId    användarens id
     */
    public void saveAsUnidentified(UUID sessionId, UUID userId) {
        List<BirdImage> images = birdImageRepository.findByUserIdAndFolderNameStartingWith(userId, "Oidentifierade");

        Set<String> folderNumber = new HashSet<>();
        for (BirdImage image : images) {
            folderNumber.add(image.getFolderName());
        }

        String folderName = "Oidentifierade" + (folderNumber.size() + 1);

        List<BirdImage> imagesWithSameSessionId = birdImageRepository.findBySessionIdAndUserId(sessionId, userId);
        for (BirdImage image : imagesWithSameSessionId) {
            image.setFolderName(folderName);
            birdImageRepository.save(image);
        }

    }

    /**
     * Raderar alla bilder som har samma sessions id
     *
     * @param sessionId
     * @param userId
     */
    @org.springframework.transaction.annotation.Transactional
    public void deleteSession(UUID sessionId, UUID userId) {
        birdImageRepository.deleteBySessionIdAndUserId(sessionId, userId);

    }
    @org.springframework.transaction.annotation.Transactional
    public void deleteImage(UUID imageId, UUID userId) throws IOException {
        BirdImage image = birdImageRepository.findById(imageId)
                .orElseThrow(() -> new RuntimeException("Bilden hittades inte"));

        storageService.deleteImage(image.getPublicId());
        birdImageRepository.deleteByIdAndUserId(imageId, userId);
    }


    /** Från Axel, döper om mapp efter FolferName **/
    public void renameFolder(String oldName, String newName, UUID userId) {
        List<BirdImage> images = birdImageRepository.findByFolderNameAndUserId(oldName, userId);
        for (BirdImage image : images) {
            image.setFolderName(newName);
            birdImageRepository.save(image);
        }
    }

    public void moveImageToFolder(UUID imageId, UUID userId, String newFolderName) {
        // Hämtar bilden från din databas
        BirdImage image = birdImageRepository.findById(imageId)
                .orElseThrow(() -> new RuntimeException("Bilden hittades inte"));

        // Extra säkerhetskoll: Se till att personen som flyttar bilden faktiskt äger den!
        if (!image.getUserId().equals(userId)) {
            throw new RuntimeException("Obehörig: Bilden tillhör inte denna användare");
        }

        // Uppdaterar mappnamnet
        image.setFolderName(newFolderName);

        // Sparar ändringen i databasen
        birdImageRepository.save(image);
    }
    /** Från Axel, Raderar alla bilder i en mapp**/
    @org.springframework.transaction.annotation.Transactional
    public void deleteFolder(String folderName, UUID userId) throws IOException {
        List<BirdImage> images = birdImageRepository.findByFolderNameAndUserId(folderName, userId);
        for (BirdImage image: images){
            storageService.deleteImage(image.getPublicId());
        }

        birdImageRepository.deleteByFolderNameAndUserId(folderName, userId);
    }

    @Transactional
    public void deleteAllByUserId(UUID userId) {
        List<BirdImage> images = birdImageRepository.findByUserId(userId);

        for (BirdImage image : images) {
            try {
                // Försök radera bilden i molnet/storage
                storageService.deleteImage(image.getPublicId());
            } catch (Exception e) {
                // Logga felet men låt loopen fortsätta så databasen städas upp
                System.err.println("Kunde inte radera bild i molnet: " + e.getMessage());
            }
        }

        // radera poster för användaren i databasen
        birdImageRepository.deleteByUserId(userId);
    }
}
