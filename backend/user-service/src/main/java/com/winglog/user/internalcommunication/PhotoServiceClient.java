package com.winglog.user.internalcommunication;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.util.UUID;

@Component
public class PhotoServiceClient {
    private final RestClient restClient;

    @Value("${internal.secret}")
    private String internalSecret;

    @Value("${photo-service.url}")
    private String photoServiceUrl;

    public PhotoServiceClient(){
        this.restClient = RestClient.create();
    }

    public void deleteAllByUserId(UUID userId){
        restClient.delete().uri(photoServiceUrl + "/internal/photos/" + userId)
                .header("X-Internal-Secret", internalSecret).retrieve().toBodilessEntity();
    }
}