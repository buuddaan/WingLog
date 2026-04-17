package com.winglog.auth.repository;

import com.winglog.auth.model.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface UserRepository extends JpaRepository<User, UUID> {
    public boolean existsByUsername (String username);
    public boolean existsByEmail (String email);
    public Optional<User> findByUsername(String username);
    public Optional<User> findByEmail(String email);
}
