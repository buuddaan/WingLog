package com.winglog.photo.service;

import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import javax.annotation.PostConstruct;
import java.io.IOException;
import java.util.Map;


@Service
public class StorageService {

    private Cloudinary cloudinary;

    @Value("${cloudinary.cloud-name}")
    private String cloudName;

    @Value("${cloudinary.api-key}")
    private String apiKey;

    @Value("${cloudinary.api-secret}")
    private String apiSecret;

    /**
     * Konfigurerar uppkopplingen mot Cloudinary med hjälp av credentials
     * från application-local.properties
     */
    @PostConstruct
    public void init() {
        this.cloudinary = new Cloudinary(ObjectUtils.asMap(
                "cloud_name", cloudName,
                "api_key", apiKey,
                "api_secret", apiSecret
        ));
    }

    /**
     * Laddar upp en bild till Cloudinary och returnerar en URL till bilden.
     *
     * @param file bildfilen som ska laddas upp
     * @return String en HTTPS URL till den uppladdade bilden i cloudinary
     * @throws IOException om et fel uppstår vid läsning av bildfilen
     */
    public String uploadImage(MultipartFile file) throws IOException {
        byte[] imageBytes = file.getBytes();
        Map uploadResult = cloudinary.uploader().upload(imageBytes, ObjectUtils.emptyMap());
        return (String) uploadResult.get("secure_url");
    }


}
