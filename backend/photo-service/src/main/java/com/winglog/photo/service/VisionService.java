package com.winglog.photo.service;

import com.google.cloud.vision.v1.*;
import com.winglog.photo.dto.BirdCandidate;
import com.winglog.photo.dto.IdentifyResponse;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import com.google.protobuf.ByteString;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;


@Service

public class VisionService {

    /**
     * identifierar fågelart på en bild med Google Cloud Vision API.
     *
     * @param image bilden som ska identifieras skickas som MultipartFile
     * @return IdentifyResponse en lista innehållande BirdCandidate bestående av artnamn och sannolikhet
     * @throws IOException      om bild inte kan läsas
     * @throws RuntimeException om API inte kan identifiera bilden
     */
    public IdentifyResponse identifyBirdImage(MultipartFile image) throws IOException {
        try (ImageAnnotatorClient client = ImageAnnotatorClient.create()) {

            byte[] imageBytes = image.getBytes();
            ByteString byteString = ByteString.copyFrom(imageBytes);

            List<AnnotateImageRequest> requests = new ArrayList<>();
            Image img = Image.newBuilder().setContent(byteString).build();
            Feature feature = Feature.newBuilder().setType(Feature.Type.WEB_DETECTION).build();
            AnnotateImageRequest request = AnnotateImageRequest.newBuilder().addFeatures(feature).setImage(img).build();
            requests.add(request);

            BatchAnnotateImagesResponse response = client.batchAnnotateImages(requests);
            List<AnnotateImageResponse> responses = response.getResponsesList();

            List<BirdCandidate> candidates = new ArrayList<>();

            for (AnnotateImageResponse res : responses) {
                if (res.hasError()) {
                    throw new RuntimeException("Fågeln kunde inte identifieras, försök med en annan bild");
                }
                
                WebDetection webDetection = res.getWebDetection();

                for (WebDetection.WebEntity entity : webDetection.getWebEntitiesList()) {
                    candidates.add(new BirdCandidate(entity.getDescription(), (double) entity.getScore()));
                }
            }

            return new IdentifyResponse(candidates);
        }

    }
}
