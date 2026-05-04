package com.winglog.user;

import com.winglog.user.dto.CreateProfileRequest;
import com.winglog.user.dto.UpdateProfileRequest;
import com.winglog.user.dto.UserProfileResponse;
import com.winglog.user.model.UserProfile;
import com.winglog.user.repository.UserProfileRepository;
import com.winglog.user.service.UserService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import static org.mockito.ArgumentMatchers.any;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import java.util.Optional;
import java.util.UUID;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class) // Startar Mockito utan Spring /EF

public class UserServiceTest {
    @Mock
    UserProfileRepository profileRepository; // Fakead databas /EF

    @InjectMocks
    UserService userService; // Riktig service, får in den fejkade repot /EF

    @Test
    void getMyProfile_profileExists_returnsProfile() {
        UUID userId = UUID.randomUUID();
        UserProfile profile = new UserProfile(userId, "Testfågel");
        when(profileRepository.findByUserId(userId)).thenReturn(Optional.of(profile));
        // Mockar repot: returnerar testprofilen istället för att anropa databasen /EF

        UserProfileResponse result = userService.getMyProfile(userId);

        assertNotNull(result);
        assertEquals(userId, result.getUserId());
        assertEquals("Testfågel", result.getDisplayName());
    }

    @Test
    void getMyProfile_profileDoesNotExist_throwsException() {
        UUID userId = UUID.randomUUID();
        when(profileRepository.findByUserId(userId)).thenReturn(Optional.empty());

        ResponseStatusException ex = assertThrows(
                ResponseStatusException.class,
                () -> userService.getMyProfile(userId)
        );
        assertEquals(HttpStatus.NOT_FOUND, ex.getStatusCode());
    }

    @Test
    void getPublicProfile_profileExists_returnsProfile() {
        UUID userId = UUID.randomUUID();
        UserProfile profile = new UserProfile(userId, "Testfågel");
        when(profileRepository.findByUserId(userId)).thenReturn(Optional.of(profile));

        UserProfileResponse result = userService.getPublicProfile(userId);

        assertNotNull(result);
        assertEquals(userId, result.getUserId());
        assertEquals("Testfågel", result.getDisplayName());
    }

    @Test
    void getPublicProfile_profileDoesNotExist_throwsException() {
        UUID userId = UUID.randomUUID();
        when(profileRepository.findByUserId(userId)).thenReturn(Optional.empty());

        ResponseStatusException ex = assertThrows(
                ResponseStatusException.class,
                () -> userService.getPublicProfile(userId)
        );
        assertEquals(HttpStatus.NOT_FOUND, ex.getStatusCode());
    }

    @Test
    void updateProfile_allFieldsProvided_updatesAndReturnsProfile() {
        UUID userId = UUID.randomUUID();
        UserProfile existing = new UserProfile(userId, "Gammalt namn");
        when(profileRepository.findByUserId(userId)).thenReturn(Optional.of(existing));
        when(profileRepository.save(existing)).thenReturn(existing);

        UpdateProfileRequest request = new UpdateProfileRequest();
        request.setDisplayName("Nytt namn");
        request.setBio("Ny bio");
        request.setProfilePhotoUrl("https://example.com/foto.jpg");

        UserProfileResponse result = userService.updateProfile(userId, request);

        assertEquals("Nytt namn", result.getDisplayName());
        assertEquals("Ny bio", result.getBio());
        assertEquals("https://example.com/foto.jpg", result.getProfilePhotoUrl());
        verify(profileRepository, times(1)).save(existing);
    }

    @Test
    void updateProfile_onlyBio_onlyBioUpdated()  {
        UUID userId = UUID.randomUUID();
        UserProfile existing = new UserProfile(userId, "Gammalt namn");
        when(profileRepository.findByUserId(userId)).thenReturn(Optional.of(existing));
        when(profileRepository.save(existing)).thenReturn(existing);

        UpdateProfileRequest request = new UpdateProfileRequest();
        request.setBio("Ny bio");

        UserProfileResponse result = userService.updateProfile(userId, request);

        assertEquals("Gammalt namn", result.getDisplayName());
        assertEquals("Ny bio", result.getBio());
        verify(profileRepository, times(1)).save(existing);
    }

    @Test
    void updateProfile_profileDoesNotExist_throwsException() {
        UUID userId = UUID.randomUUID();
        when(profileRepository.findByUserId(userId)).thenReturn(Optional.empty());

        UpdateProfileRequest request = new UpdateProfileRequest();
        request.setDisplayName("Nytt namn");

        ResponseStatusException ex = assertThrows(
                ResponseStatusException.class,
                () -> userService.updateProfile(userId, request)
        );
        assertEquals(HttpStatus.NOT_FOUND, ex.getStatusCode());
    }

    // Tom sträng i displayName ska inte skriva över befintligt namn, hanteras av isBlank() i UserService /EF
    @Test
    void updateProfile_emptyDisplayName_doesNotOverwriteExistingName() {
        UUID userId = UUID.randomUUID();
        UserProfile existing = new UserProfile(userId, "Gammalt namn");
        when(profileRepository.findByUserId(userId)).thenReturn(Optional.of(existing));
        when(profileRepository.save(existing)).thenReturn(existing);

        UpdateProfileRequest request = new UpdateProfileRequest();
        request.setDisplayName("");

        UserProfileResponse result = userService.updateProfile(userId, request);
        assertFalse(result.getDisplayName().isBlank());
    }

    @Test
    void createProfile_profileDoesNotExist_createsAndReturnsProfile() {
        UUID userId = UUID.randomUUID();
        CreateProfileRequest request = new CreateProfileRequest();
        request.setUserId(userId);
        request.setDisplayName("Ny fågel");

        when(profileRepository.existsByUserId(userId)).thenReturn(false);
        when(profileRepository.save(any(UserProfile.class))).thenAnswer(i -> i.getArgument(0));

        UserProfileResponse result = userService.createProfile(request);

        assertEquals(userId, result.getUserId());
        assertEquals("Ny fågel", result.getDisplayName());
        verify(profileRepository, times(1)).save(any(UserProfile.class));
    }

    @Test
    void createProfile_profileAlreadyExists_returnsExistingWithoutSaving() {
        UUID userId = UUID.randomUUID();
        UserProfile existing = new UserProfile(userId, "Befintlig fågel");
        CreateProfileRequest request = new CreateProfileRequest();
        request.setUserId(userId);
        request.setDisplayName("Befintlig fågel");

        when(profileRepository.existsByUserId(userId)).thenReturn(true);
        when(profileRepository.findByUserId(userId)).thenReturn(Optional.of(existing));

        UserProfileResponse result = userService.createProfile(request);

        assertEquals(userId, result.getUserId());
        assertEquals("Befintlig fågel", result.getDisplayName());
        verify(profileRepository, never()).save(any());
    }

    @Test
    void deleteAccount_profileExists_deletesProfile() {
        UUID userId = UUID.randomUUID();
        when(profileRepository.existsByUserId(userId)).thenReturn(true);
        userService.deleteAccount(userId);
        verify(profileRepository, times(1)).deleteByUserId(userId);
    }

    @Test
    void deleteAccount_profileDoesNotExist_throwsException() {
        UUID userId = UUID.randomUUID();
        when(profileRepository.existsByUserId(userId)).thenReturn(false);

        ResponseStatusException ex = assertThrows(
                ResponseStatusException.class,
                () -> userService.deleteAccount(userId)
        );
        assertEquals(HttpStatus.NOT_FOUND, ex.getStatusCode());
        verify(profileRepository, never()).deleteByUserId(any());
    }

}
