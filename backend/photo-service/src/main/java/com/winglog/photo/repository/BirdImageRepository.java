package com.winglog.photo.repository;

import com.winglog.photo.model.BirdImage;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface BirdImageRepository extends JpaRepository<BirdImage, UUID> {
    List<BirdImage> findByUserId(UUID userId);

    List<BirdImage> findByFolderNameAndUserId(String folderName, UUID userId);

    List<BirdImage> findByUserIdAndFolderNameIsNull(UUID userId);

    List<BirdImage> findBySessionId(UUID sessionId);


}
