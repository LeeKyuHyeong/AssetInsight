package com.example.assetinsight.data.local.dao;

import androidx.room.Dao;
import androidx.room.Delete;
import androidx.room.Insert;
import androidx.room.OnConflictStrategy;
import androidx.room.Query;
import androidx.room.Update;

import com.example.assetinsight.data.local.entity.UserProfile;

import java.util.List;

/**
 * UserProfile DAO
 */
@Dao
public interface UserProfileDao {

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    void insert(UserProfile profile);

    @Update
    void update(UserProfile profile);

    @Delete
    void delete(UserProfile profile);

    @Query("SELECT * FROM user_profile WHERE id = :userId")
    UserProfile getById(String userId);

    @Query("SELECT * FROM user_profile WHERE isActive = 1 LIMIT 1")
    UserProfile getActiveProfile();

    @Query("SELECT * FROM user_profile ORDER BY createdAt DESC")
    List<UserProfile> getAllProfiles();

    @Query("UPDATE user_profile SET isActive = 0")
    void deactivateAll();

    @Query("UPDATE user_profile SET isActive = 1 WHERE id = :userId")
    void activateProfile(String userId);

    @Query("UPDATE user_profile SET lastSyncTime = :syncTime WHERE id = :userId")
    void updateLastSyncTime(String userId, long syncTime);

    @Query("SELECT COUNT(*) FROM user_profile")
    int getProfileCount();

    @Query("DELETE FROM user_profile WHERE id = :userId")
    void deleteById(String userId);
}
