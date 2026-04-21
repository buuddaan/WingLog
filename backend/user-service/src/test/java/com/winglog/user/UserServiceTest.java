package com.winglog.user;

import com.winglog.user.dto.response.UserProfileResponse;
import com.winglog.user.model.UserProfile;
import com.winglog.user.repository.UserProfileRepository;
import com.winglog.user.service.UserService;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class) //Startar Mockito utan Spring /EF

public class UserServiceTest {
    @Mock
    UserProfileRepository profileRepository; //Fejkad databas /EF

    @InjectMocks
    UserService userService; //Riktig service, får in den fejkade repot /EF

    /** Happy path: profil finns och returnerar korrekt DTO
     - ska inte returnera null
     - userId får ej tappas bort i fromModel()
     - displayName ska mappas korrekt */
    @Test
    void getMyProfile_profileExists_returnsProfile() {
        UUID userId = UUID.randomUUID();
        UserProfile profile = new UserProfile(userId, "Testfågel");
        when(profileRepository.findByUserId(userId)).thenReturn(Optional.of(profile));

        UserProfileResponse result = userService.getMyProfile(userId);

        assertNotNull(result);
        assertEquals(userId, result.getUserId());
        assertEquals("Testfågel", result.getDisplayName());
    }

    /** Exception path: profil saknas → kastar RuntimeException /EF
     - orElseThrow() ska triggas när repot returnerar tomt
     - felmeddelandet ska innehålla "Profil hittades inte" */
    @Test
    void getMyProfile_profileDoesNotExist_throwsException() {
        UUID userId = UUID.randomUUID();
        when(profileRepository.findByUserId(userId)).thenReturn(Optional.empty());

        RuntimeException ex = assertThrows(
                RuntimeException.class,
                () -> userService.getMyProfile(userId)
        );
        assertTrue(ex.getMessage().contains("Profil hittades inte"));
    }

    /** Happy path: profil finns och returnerar korrekt DTO
     - userId ska mappas korrekt
     - displayName ska mappas korrekt */
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

    /** Exception path: profil saknas -> kastar RuntimeException
    - orElseThrow() ska triggas när repot returnerar tomt
    - felmeddelandet ska innehålla "Profil hittades inte" */
    @Test
    void getPublicProfile_profileDoesNotExist_throwsException() {
        UUID userId = UUID.randomUUID();
        when(profileRepository.findByUserId(userId)).thenReturn(Optional.empty());

        RuntimeException ex = assertThrows(
                RuntimeException.class,
                () -> userService.getPublicProfile(userId)
        );
        assertTrue(ex.getMessage().contains("Profil hittades inte"));
    }

}
