package com.winglog.user.dto;

import com.winglog.user.model.UserProfile;
import java.util.UUID;

public class UserProfileResponse {

    private UUID userId;
    private String displayName;
    private String bio;
    private String profilePhotoUrl;

    public UserProfileResponse() {}

    public UserProfileResponse(UUID userId, String displayName,
                               String bio, String profilePhotoUrl) {
        this.userId = userId;
        this.displayName = displayName;
        this.bio = bio;
        this.profilePhotoUrl = profilePhotoUrl;
    }

    public static UserProfileResponse fromModel(UserProfile profile) {
        return new UserProfileResponse(
                profile.getUserId(),
                profile.getDisplayName(),
                profile.getBio(),
                profile.getProfilePhotoUrl()
        );
    }

    public UUID getUserId() { return userId; }
    public String getDisplayName() { return displayName; }
    public String getBio() { return bio; }
    public String getProfilePhotoUrl() { return profilePhotoUrl; }
}