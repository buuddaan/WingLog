package com.winglog.user.service;

import com.winglog.user.dto.request.CreateProfileRequest;
import com.winglog.user.dto.request.UpdateProfileRequest;
import com.winglog.user.dto.response.UserProfileResponse;
import com.winglog.user.database.UserProfile;
import com.winglog.user.repository.UserProfileRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;

@Service
public class UserService {
    private final UserProfileRepository profileRepository;

    public UserService(UserProfileRepository profileRepository) {
        this.profileRepository = profileRepository;
    }

    public UserProfileResponse getMyProfile(UUID userId) {
        UserProfile profile = profileRepository.findByUserId(userId)
                .orElseThrow(() -> new RuntimeException(
                        "Profil hittades inte för userId: " + userId
                ));

        return UserProfileResponse.fromModel(profile);
    }

    public UserProfileResponse getPublicProfile(UUID targetUserId) {
        UserProfile profile = profileRepository.findByUserId(targetUserId)
                .orElseThrow(() -> new RuntimeException("Profil hittades inte"));

        return UserProfileResponse.fromModel(profile);
    }

    @Transactional
    public UserProfileResponse updateProfile(UUID userId, UpdateProfileRequest request) {
        UserProfile profile = profileRepository.findByUserId(userId)
                .orElseThrow(() -> new RuntimeException("Profil hittades inte"));

        if (request.getDisplayName() != null) {
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

    public UserProfileResponse createProfile(CreateProfileRequest request) {
        if (profileRepository.existsByUserId(request.getUserId())) {
            UserProfile existing = profileRepository.findByUserId(request.getUserId()).get();
            return UserProfileResponse.fromModel(existing);
        }

        UserProfile profile = new UserProfile(
                request.getUserId(),
                request.getDisplayName()
        );
        profileRepository.save(profile);

        return UserProfileResponse.fromModel(profile);
    }

    @Transactional
    public void deleteAccount(UUID userId) {
        if (!profileRepository.existsByUserId(userId)) {
            throw new RuntimeException("Profil hittades inte");
        }

        profileRepository.deleteByUserId(userId);

        //TODO: Anropa auth-service för att radera credentials:
        // DELETE http://auth-service:8081/internal/users/{userId}
        // Läggs till när auth-service har den endpointen klar
    }
}