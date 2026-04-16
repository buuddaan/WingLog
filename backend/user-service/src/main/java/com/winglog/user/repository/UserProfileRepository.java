package com.winglog.user.repository;
//Databas-accessen /EF

import com.winglog.user.database.UserProfile;
import org.springframework.data.jpa.repository.JpaRepository; //Ger save(), findById(), deleteById(), findAll() mm
import org.springframework.stereotype.Repository;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserProfileRepository extends JpaRepository<UserProfile, UUID> {
    Optional<UserProfile> findByUserId(UUID userId); //Ifall vi ej hittar profilen, don't die
    void deleteByUserId(UUID userId);
    boolean existsByUserId(UUID userId);
}