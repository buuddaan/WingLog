package com.winglog.photo.Repository;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface PhotoRepository extends JpaRepository<BirdImage, UUID> {

List<BirdImage> findByUserId(UUID userId);

List<BirdImage> findByFolderId(UUID folderId);

void deleteByIdAndUserId(UUID id, UUID userId);

}
