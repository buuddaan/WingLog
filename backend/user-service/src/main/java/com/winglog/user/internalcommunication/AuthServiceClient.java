package com.winglog.user.internalcommunication;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.util.UUID;

@Component
public class AuthServiceClient {
    private final RestClient restClient;

    @Value("${internal.secret}")
    private String internalSecret;

    @Value("${auth-service.url}")
    private String authServiceUrl;

    public AuthServiceClient(){
        this.restClient = RestClient.create();
    }

    public void deleteUser(UUID userId){
        restClient.delete().uri(authServiceUrl + "/internal/users/" + userId)
        .header("X-Internal-Secret", internalSecret).retrieve().toBodilessEntity();
    }
}
