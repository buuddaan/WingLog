package com.winglog.auth.repository;

import com.winglog.auth.model.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface UserRepository extends JpaRepository<User, UUID> {

    /**
     * letar efter användarnamnet i databasen
     *
     * @param username som tillhör användaren
     * @return true om användarnamnet finns. false om användarnamnet inte hittas.
     */
    public boolean existsByUsername(String username);

    /**
     * letar efter emailadress i databasen
     *
     * @param email som tillhör användaren
     * @return true om email finns. false om email inte hittas.
     */
    public boolean existsByEmail(String email);

    /**
     * letar efter en användare med hjälp av användarnamn
     *
     * @param username som tillhör användaren
     * @return Optional innehållande User om användarnamnet hittades. tomt Optional om användarnamnet inte hittades.
     */
    public Optional<User> findByUsername(String username);

    /**
     * letar efter en användare med hjälp av email
     *
     * @param email som tillhör användaren
     * @return Optional innehållande User om email hittades annars tomt Optional
     */
    public Optional<User> findByEmail(String email);


}
