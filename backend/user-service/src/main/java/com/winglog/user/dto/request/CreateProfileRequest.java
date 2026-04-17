package com.winglog.user.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.util.UUID;

public class CreateProfileRequest {

    @NotNull(message = "userId får inte vara null")
    private UUID userId;

    @NotBlank(message = "displayName får inte vara tomt")
    private String displayName;

    public CreateProfileRequest() {}

    public CreateProfileRequest(UUID userId, String displayName) {
        this.userId = userId;
        this.displayName = displayName;
    }

    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }

    public String getDisplayName() { return displayName; }
    public void setDisplayName(String displayName) { this.displayName = displayName; }
}