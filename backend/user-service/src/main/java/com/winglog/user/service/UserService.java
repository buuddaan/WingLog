package com.winglog.user.service;

import com.winglog.user.dto.request.CreateProfileRequest;
import com.winglog.user.dto.request.UpdateProfileRequest;
import com.winglog.user.dto.response.UserProfileResponse;
import com.winglog.user.internalcommunication.AuthServiceClient;
import com.winglog.user.internalcommunication.PhotoServiceClient;
import com.winglog.user.model.UserProfile;
import com.winglog.user.repository.UserProfileRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import java.util.UUID;

// UserService: Hanterar logik för användarprofiler: läsning, uppdatering, skapande och radering /EF
@Service
public class UserService {
    private final UserProfileRepository profileRepository;
    private final AuthServiceClient authServiceClient;
    private final PhotoServiceClient photoServiceClient;

    public UserService(UserProfileRepository profileRepository, AuthServiceClient authServiceClient, PhotoServiceClient photoServiceClient) {
        this.profileRepository = profileRepository;
        this.authServiceClient = authServiceClient;
        this.photoServiceClient = photoServiceClient;
    }

    // Hämtar den inloggade användarens egen profil /EF
    public UserProfileResponse getMyProfile(UUID userId) {
        UserProfile profile = profileRepository.findByUserId(userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Profil hittades inte"));

        return UserProfileResponse.fromModel(profile);
    }

    // Hämtar en annan användares publika profil (exempelvis vid klick i forumet) /EF
    public UserProfileResponse getPublicProfile(UUID targetUserId) {
        UserProfile profile = profileRepository.findByUserId(targetUserId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Profil hittades inte"));

        return UserProfileResponse.fromModel(profile);
    }

    // Uppdaterar bara de fält som faktiskt skickats. Null och tomma strängar ignoreras
    @Transactional // Rollback alla databasändringar om något går fel
    public UserProfileResponse updateProfile(UUID userId, UpdateProfileRequest request) {
        UserProfile profile = profileRepository.findByUserId(userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Profil hittades inte"));

        if (request.getDisplayName() != null && !request.getDisplayName().isBlank()) {
            profile.setDisplayName(request.getDisplayName());
        }
        if (request.getBio() != null) {
            profile.setBio(request.getBio());
        }
        if (request.getProfilePhotoUrl() != null) {
            profile.setProfilePhotoUrl(request.getProfilePhotoUrl());
        }
        profileRepository.save(profile);

        return UserProfileResponse.fromModel(profile);
    }

    // Anropas av auth-service via /internal/profiles vid registrering. Returnerar utan att spara igen (idempotent) /EF
    public UserProfileResponse createProfile(CreateProfileRequest request) {
        if (profileRepository.existsByUserId(request.getUserId())) {
            UserProfile existing = profileRepository.findByUserId(request.getUserId()).get();
            // Profil finns redan — returnera utan att spara igen /EF
            return UserProfileResponse.fromModel(existing);
        }

        UserProfile profile = new UserProfile(
                request.getUserId(),
                request.getDisplayName()
        );
        profileRepository.save(profile);

        return UserProfileResponse.fromModel(profile);
    }

    // Raderar användarprofilen. Credentials raderas av auth-service separat /EF
    @Transactional
    public void deleteAccount(UUID userId) {
        //Radera profilen
        if (profileRepository.existsByUserId(userId)) {
            profileRepository.deleteByUserId(userId);
        }

        // Radera bilder (utan exception som stoppar raderingen)
        try {
            photoServiceClient.deleteAllByUserId(userId);
        } catch (Exception e) {
            // Logga felet men fortsätt
            System.err.println("Kunde inte radera bilder: " + e.getMessage());
        }

        // Radera inloggning (utan att kasta exception som stoppar raderingen)
        try {
            authServiceClient.deleteUser(userId);
        } catch (Exception e) {
            // Logga felet men fortsätt
            System.err.println("Kunde inte radera auth-user: " + e.getMessage());
        }
    }
}