package com.winglog.photo.repository;

import com.winglog.photo.model.BirdImage;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface PhotoRepository extends JpaRepository<BirdImage, UUID> {

List<BirdImage> findByUserId(UUID userId);

List<BirdImage> findByFolderId(UUID folderId);

void deleteByIdAndUserId(UUID id, UUID userId);

}
