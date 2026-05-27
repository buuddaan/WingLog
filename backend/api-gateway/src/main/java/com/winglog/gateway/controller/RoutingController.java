package com.winglog.gateway.controller;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.http.client.JdkClientHttpRequestFactory;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientResponseException;

import java.net.http.HttpClient;

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

    @Value("${photo-service.url}")
    private String photoServiceUrl;

    @Value("${audio-service.url}")
    private String audioServiceUrl;

    public RoutingController() {
        HttpClient httpClient = HttpClient.newBuilder()
                .followRedirects(HttpClient.Redirect.NEVER)
                .build();
        this.restClient = RestClient.builder()
                .requestFactory(new JdkClientHttpRequestFactory(httpClient))
                .build();
    }

    // Fångar upp ALLA requests under /gateway/**
    @RequestMapping("/**")
    public ResponseEntity<byte[]> route(
            HttpServletRequest request,
            // Axel, byte[] istället för String för att klara av filer
            @RequestBody(required = false) byte[] body) {

        String path = request.getRequestURI();
        String method = request.getMethod();

        // NYTT: Hämta query-parametrar (allt efter ?)
        String queryString = request.getQueryString();

        // Tar fram targetUrl och anropar den
        String targetUrl = resolveTargetUrl(path);

        if (targetUrl == null) {
            return ResponseEntity.notFound().build();
        }

        // NYTT: Klistra på parametrarna på url:en igen innan vi skickar vidare
        if (queryString != null) {
            targetUrl = targetUrl + "?" + queryString;
        }

        // Hämta email och userId som JwtAuthFilter lade på requesten
        String userEmail = (String) request.getAttribute("X-User-Email");
        String userId = (String) request.getAttribute("X-User-Id");

        // Axel, Läs av vilket format Flutter-appen skickade (t.ex. multipart för filer)
        String contentType = request.getContentType();

        // Bygg och skicka vidare requesten
        RestClient.RequestBodySpec requestSpec = restClient
                .method(HttpMethod.valueOf(method))
                .uri(java.net.URI.create(targetUrl));



        // DETTA ÄR VALIDERINGEN
        // Axel,  Hitta rätt Content-Type istället för att hårdkoda JSON
        if (contentType != null) {
            requestSpec.header("Content-Type", contentType);
        } else {
            requestSpec.header("Content-Type", "application/json");
        }

        // Vidarebefordra email om den finns
        if (userEmail != null) {
            requestSpec.header("X-User-Email", userEmail);
        }

        // Vidarebefordra userId så downstream-services kan identifiera användaren
        if (userId != null) {
            requestSpec.header("X-User-Id", userId);
        }

        // Lägg till body om det finns en (POST/PUT)
        if (body != null) {
            requestSpec.body(body);
        }

        // Returnera byte[] istället för String

        // OBS: Nu kallar gateway på auth, auth anropar microservice. Detta är inte korrekt
        // Auth ska istället för att anropa ms bara bekräfta autenisering eller ej tillbaka till gateway som efter detta anropar korrekt service
        try {
            ResponseEntity<byte[]> r = requestSpec.retrieve().toEntity(byte[].class);
            return ResponseEntity.status(r.getStatusCode()).body(r.getBody());
        } catch (RestClientResponseException e) {
            return ResponseEntity.status(e.getStatusCode()).body(e.getResponseBodyAsByteArray());
        }
    }

    private String resolveTargetUrl(String path) {
        // Ta bort /gateway-prefixet
        String strippedPath = path.replaceFirst("/gateway", "");

        if (strippedPath.startsWith("/oauth2") || strippedPath.startsWith("/login/oauth2")) {
            return authServiceUrl + strippedPath;
        } else if (strippedPath.startsWith("/auth")) {
            return authServiceUrl + strippedPath;
        } else if (strippedPath.startsWith("/users")) {
            return userServiceUrl + strippedPath;
        } else if (strippedPath.startsWith("/sightings")) {
            return geoServiceUrl + strippedPath;
        } else if (strippedPath.startsWith("/photos")) {
            return photoServiceUrl + strippedPath;
        } else if (strippedPath.startsWith("/audio")) {
            return audioServiceUrl + strippedPath;
        }

        return null;
    }
}