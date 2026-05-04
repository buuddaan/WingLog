package com.winglog.user.dto;

import jakarta.validation.constraints.Size;

public class UpdateProfileRequest {

    @Size(min = 1, max = 100, message = "displayName måste vara 1-100 tecken")
    private String displayName;

    @Size(max = 500, message = "bio får vara max 500 tecken")
    private String bio;

    @Size(max = 500, message = "profilePhotoUrl får vara max 500 tecken")
    private String profilePhotoUrl;

    public UpdateProfileRequest() {}

    public String getDisplayName() { return displayName; }
    public void setDisplayName(String displayName) { this.displayName = displayName; }

    public String getBio() { return bio; }
    public void setBio(String bio) { this.bio = bio; }

    public String getProfilePhotoUrl() { return profilePhotoUrl; }
    public void setProfilePhotoUrl(String url) { this.profilePhotoUrl = url; }
}