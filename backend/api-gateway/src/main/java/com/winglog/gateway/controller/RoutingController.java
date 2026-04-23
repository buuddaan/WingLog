package com.winglog.gateway.controller;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestClient;

import java.util.Collections;

@RestController
public class RoutingController {

    private final RestClient restClient;

    @Value("${auth-service.url}")
    private String authServiceUrl;

    @Value("${user-service.url}")
    private String userServiceUrl;

    @Value("${post-service.url}")
    private String postServiceUrl;

    @Value("${forum-service.url}")
    private String forumServiceUrl;

    @Value("${geo-service.url}")
    private String geoServiceUrl;

    @Value("${media-service.url}")
    private String mediaServiceUrl;

    @Value("${audio-service.url}")
    private String audioServiceUrl;

    public RoutingController() {
        this.restClient = RestClient.create();
    }

    // Fångar upp ALLA requests under /gateway/**
    @RequestMapping("/**")
    public ResponseEntity<String> route(
            HttpServletRequest request,
            @RequestBody(required = false) String body) {

        String path = request.getRequestURI();
        String method = request.getMethod();
        String targetUrl = resolveTargetUrl(path);

        if (targetUrl == null) {
            return ResponseEntity.notFound().build();
        }

        // Hämta email och userId som JwtAuthFilter lade på requesten /EF
        String userEmail = (String) request.getAttribute("X-User-Email");
        String userId = (String) request.getAttribute("X-User-Id");

        // Bygg och skicka vidare requesten
        RestClient.RequestBodySpec requestSpec = restClient
                .method(HttpMethod.valueOf(method))
                .uri(targetUrl)
                .header("Content-Type", "application/json");

        // Vidarebefordra email om den finns /EF
        if (userEmail != null) {
            requestSpec.header("X-User-Email", userEmail);
        }

        // Vidarebefordra userId så downstream-services kan identifiera användaren /EF
        if (userId != null) {
            requestSpec.header("X-User-Id", userId);
        }

        // Lägg till body om det finns en (POST/PUT)
        if (body != null) {
            requestSpec.body(body);
        }

        return requestSpec.retrieve().toEntity(String.class);
    }

    /**
     * Avgör vilken service som ska ta emot requesten baserat på path.
     * /gateway/auth/**   → auth-service
     * /gateway/users/**  → user-service
     * /gateway/posts/**  → post-service
     * /gateway/feed/**   → post-service
     * /gateway/forums/** → forum-service
     * /gateway/sightings/** → geo-service
     * /gateway/media/**  → media-service
     * /gateway/audio/**  → audio-service
     */
    private String resolveTargetUrl(String path) {
        // Ta bort /gateway-prefixet
        String strippedPath = path.replaceFirst("/gateway", "");

        if (strippedPath.startsWith("/auth")) {
            return authServiceUrl + strippedPath;
        } else if (strippedPath.startsWith("/users")) {
            return userServiceUrl + strippedPath;
        } else if (strippedPath.startsWith("/posts") || strippedPath.startsWith("/feed")) {
            return postServiceUrl + strippedPath;
        } else if (strippedPath.startsWith("/forums") || strippedPath.startsWith("/threads")) {
            return forumServiceUrl + strippedPath;
        } else if (strippedPath.startsWith("/sightings") || strippedPath.startsWith("/species")) {
            return geoServiceUrl + strippedPath;
        } else if (strippedPath.startsWith("/media")) {
            return mediaServiceUrl + strippedPath;
        } else if (strippedPath.startsWith("/audio")) {
            return audioServiceUrl + strippedPath;
        }

        return null;
    }
}