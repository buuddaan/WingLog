package com.winglog.geo;

import com.winglog.geo.dto.SightingRequest;
import com.winglog.geo.dto.SightingResponse;
import com.winglog.geo.entity.Sighting;
import com.winglog.geo.repository.SightingRepository;
import com.winglog.geo.service.SightingService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.Point;
import org.locationtech.jts.geom.PrecisionModel;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

// Enhetstester för SightingService. Repository mockas för att isolera affärslogiken /EF
@ExtendWith(MockitoExtension.class)
class SightingServiceTest {

    @Mock private SightingRepository sightingRepository;
    @InjectMocks private SightingService sightingService;

    private final GeometryFactory geometryFactory = new GeometryFactory(new PrecisionModel(), 4326);
    private final UUID ownerId = UUID.fromString("11111111-1111-1111-1111-111111111111");
    private final UUID otherUserId = UUID.fromString("22222222-2222-2222-2222-222222222222");
    private final UUID sightingId = UUID.fromString("33333333-3333-3333-3333-333333333333");

    // Sätter privata fält via reflection eftersom @PrePersist inte körs i enhetstester /EF
    private void setPrivateField(Sighting s, String fieldName, Object value) {
        try {
            var f = Sighting.class.getDeclaredField(fieldName);
            f.setAccessible(true);
            f.set(s, value);
        } catch (ReflectiveOperationException e) {
            throw new RuntimeException(e);
        }
    }

    private Sighting buildSighting(UUID owner, UUID id, double lat, double lng, boolean isPublic) {
        Sighting s = new Sighting();
        setPrivateField(s, "id", id);
        setPrivateField(s, "createdAt", LocalDateTime.now().minusDays(1));
        s.setUserId(owner);
        s.setSpeciesName("Talgoxe");
        s.setLocation(geometryFactory.createPoint(new Coordinate(lng, lat)));
        s.setDescription("Beskrivning");
        s.setPublic(isPublic);
        return s;
    }

    private SightingRequest buildRequest(double lat, double lng, String species, boolean isPublic) {
        SightingRequest r = new SightingRequest();
        r.setLatitude(lat);
        r.setLongitude(lng);
        r.setSpeciesName(species);
        r.setDescription("Test");
        r.setPublic(isPublic);
        return r;
    }

    // Mock-svar som simulerar Hibernates @PrePersist /EF
    private void mockSaveAssignsIdAndTimestamp() {
        when(sightingRepository.save(any(Sighting.class))).thenAnswer(inv -> {
            Sighting toSave = inv.getArgument(0);
            setPrivateField(toSave, "id", sightingId);
            setPrivateField(toSave, "createdAt", LocalDateTime.now());
            return toSave;
        });
    }

    // TEST 1: deleteSighting med fel userId → 403, ingen radering /EF
    @Test
    void deleteSighting_withWrongUserId_returns403_AndDoesNotDelete() {
        when(sightingRepository.findById(sightingId))
                .thenReturn(Optional.of(buildSighting(ownerId, sightingId, 59.33, 18.07, true)));

        assertThatThrownBy(() -> sightingService.deleteSighting(sightingId, otherUserId))
                .isInstanceOf(ResponseStatusException.class)
                .extracting(e -> ((ResponseStatusException) e).getStatusCode())
                .isEqualTo(HttpStatus.FORBIDDEN);

        verify(sightingRepository, never()).deleteByEntityId(any());
        verify(sightingRepository, never()).delete(any());
    }

    // TEST 2: updateSighting med fel userId → 403, save kallas aldrig /EF
    @Test
    void updateSighting_withWrongUserId_returns403_AndDoesNotSave() {
        when(sightingRepository.findById(sightingId))
                .thenReturn(Optional.of(buildSighting(ownerId, sightingId, 59.33, 18.07, true)));

        SightingRequest req = buildRequest(60.0, 19.0, "Gråsparv", false);

        assertThatThrownBy(() -> sightingService.updateSighting(sightingId, req, otherUserId))
                .isInstanceOf(ResponseStatusException.class)
                .extracting(e -> ((ResponseStatusException) e).getStatusCode())
                .isEqualTo(HttpStatus.FORBIDDEN);

        verify(sightingRepository, never()).save(any());
    }

    // TEST 3: lat/lng-axelordning bevaras (PostGIS/JTS lagrar X=lng, Y=lat) /EF
    @Test
    void createSighting_storesCoordinatesWithCorrectAxisOrder() {
        mockSaveAssignsIdAndTimestamp();
        SightingRequest req = buildRequest(59.33, 18.07, "Talgoxe", true);

        SightingResponse response = sightingService.createSighting(req, ownerId);

        assertThat(response.getLatitude()).isEqualTo(59.33);
        assertThat(response.getLongitude()).isEqualTo(18.07);
    }

    // TEST 5: createSighting sätter userId och returnerar korrekt SightingResponse /EF
    @Test
    void createSighting_withValidData_setsUserIdAndReturnsResponse() {
        mockSaveAssignsIdAndTimestamp();
        SightingRequest req = buildRequest(59.33, 18.07, "Koltrast", false);

        SightingResponse response = sightingService.createSighting(req, ownerId);

        assertThat(response.getUserId()).isEqualTo(ownerId);
        assertThat(response.getSpeciesName()).isEqualTo("Koltrast");
        assertThat(response.isPublic()).isFalse();
        assertThat(response.getId()).isEqualTo(sightingId);
    }

    // TEST 6: DOKUMENTATIONSTEST - getAllSightings läcker privata sightings /EF
    // TODO: Uppdatera när synlighetsmodell beslutats i teamet /EF
    @Test
    void getAllSightings_currentlyReturnsPrivateSightings() {
        UUID otherSightingId = UUID.fromString("44444444-4444-4444-4444-444444444444");
        when(sightingRepository.findAll()).thenReturn(List.of(
                buildSighting(ownerId, sightingId, 59.33, 18.07, true),
                buildSighting(otherUserId, otherSightingId, 59.40, 18.10, false)
        ));

        List<SightingResponse> result = sightingService.getAllSightings();

        assertThat(result).hasSize(2);
        assertThat(result).anyMatch(s -> !s.isPublic());
    }

    // TEST 7: getSightingById kastar 404 när sighting saknas /EF
    @Test
    void getSightingById_returns404_whenNotFound() {
        UUID missingId = UUID.fromString("99999999-9999-9999-9999-999999999999");
        when(sightingRepository.findById(missingId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> sightingService.getSightingById(missingId))
                .isInstanceOf(ResponseStatusException.class)
                .extracting(e -> ((ResponseStatusException) e).getStatusCode())
                .isEqualTo(HttpStatus.NOT_FOUND);
    }
}