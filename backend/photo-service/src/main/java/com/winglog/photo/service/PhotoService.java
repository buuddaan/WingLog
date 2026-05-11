package com.winglog.photo.service;

import com.winglog.photo.dto.IdentifyResponse;
import com.winglog.photo.dto.ImageResponse;
import com.winglog.photo.dto.UploadImageRequest;
import com.winglog.photo.model.BirdImage;
import com.winglog.photo.repository.BirdImageRepository;
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

    public PhotoService(StorageService storageService, VisionService visionService, BirdImageRepository birdImageRepository){
        this.storageService = storageService;
        this.visionService = visionService;
        this.birdImageRepository = birdImageRepository;
    }

    /**
     * Laddar upp bild till Cloudinary, sparar bildinformation i databasen.
     * @param request som innehåller bildfilen, session id datum och koordinater
     * @param userId användarens id
     * @return ImageResponse innehållande bildens information
     * @throws IOException om inte bilden kan läsas in
     */
    public ImageResponse uploadImage(UploadImageRequest request, UUID userId) throws IOException {
        String imageUrl = storageService.uploadImage(request.getImage());

        BirdImage birdImage = new BirdImage(userId,imageUrl, null, request.getSessionId(), request.getDate(), request.getLongitude(),request.getLatitude());
        birdImageRepository.save(birdImage);

        return new ImageResponse(birdImage.getId(), birdImage.getImageUrl(), birdImage.getFolderName(), birdImage.getSessionId(), birdImage.getDate(), birdImage.getLongitude(), birdImage.getLatitude());
    }

    /**
     * Identifierar fågelarten på bilden med Google Cloud Vision API.
     * @param image bilden som ska identifieras
     * @return IdentifyResponse innehållande en lista av möjliga fågelarter och hur stor sannolikheten är att det är den arten.
     * @throws IOException om bilden inte kan läsas
     */
    public IdentifyResponse identifyImage(MultipartFile image) throws IOException{
       return visionService.identifyBirdImage(image);

    }

    /**
     * Sparar alla bilder från en session i en namngiven mapp
     * @param sessionId sessionens id
     * @param userId användarens id
     * @param folderName mappnamnet
     */
    public void saveToFolder(UUID sessionId, UUID userId, String folderName){
        List<BirdImage> images = birdImageRepository.findBySessionIdAndUserId(sessionId, userId);

        for(BirdImage image : images){
            image.setFolderName(folderName);
            birdImageRepository.save(image);
        }
    }

    /**
     * Sparar alla bilder får en session i en oidentifierad mapp.
     * Mappnamn genereras automatiskt
     * @param sessionId sessionens id
     * @param userId användarens id
     */
    public void saveAsUnidentified(UUID sessionId, UUID userId){
        List<BirdImage> images = birdImageRepository.findByUserIdAndFolderNameStartingWith(userId, "Oidentifierade");

        Set<String> folderNumber = new HashSet<>();
        for(BirdImage image : images) {
            folderNumber.add(image.getFolderName());
        }

        String folderName = "Oidentifierade" + (folderNumber.size() + 1);

        List<BirdImage> imagesWithSameSessionId = birdImageRepository.findBySessionIdAndUserId(sessionId,userId);
        for(BirdImage image : imagesWithSameSessionId){
            image.setFolderName(folderName);
            birdImageRepository.save(image);
        }

    }

    /**
     * Raderar alla bilder som har samma sessions id
     * @param sessionId
     * @param userId
     */
    public void deleteSession(UUID sessionId, UUID userId){
        birdImageRepository.deleteBySessionIdAndUserId(sessionId,userId);

    }

}
