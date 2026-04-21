package com.winglog.user.repository;

import com.winglog.user.model.UserProfile;
import org.springframework.data.jpa.repository.JpaRepository; //Ger save(), findById(), deleteById(), findAll() mm
import org.springframework.stereotype.Repository;
import java.util.Optional;
import java.util.UUID;

// UserProfileRepository: Databasåtkomst för användarprofiler /EF
@Repository
public interface UserProfileRepository extends JpaRepository<UserProfile, UUID> {
    Optional<UserProfile> findByUserId(UUID userId); // Returnerar Optional: kastar ej undantag om profil saknas /EF
    void deleteByUserId(UUID userId);
    boolean existsByUserId(UUID userId); // Undviker onödig hämtning av hela objektet vid existenskontroll /EF
}