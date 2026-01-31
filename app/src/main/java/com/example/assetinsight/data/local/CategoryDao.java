package com.example.assetinsight.data.local;

import androidx.room.Dao;
import androidx.room.Delete;
import androidx.room.Insert;
import androidx.room.OnConflictStrategy;
import androidx.room.Query;
import androidx.room.Update;

import java.util.List;

/**
 * 카테고리 DAO
 */
@Dao
public interface CategoryDao {

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    void insert(Category category);

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    void insertAll(List<Category> categories);

    @Update
    void update(Category category);

    @Delete
    void delete(Category category);

    @Query("DELETE FROM category WHERE id = :id")
    void deleteById(String id);

    @Query("DELETE FROM category")
    void deleteAll();

    /**
     * 모든 카테고리 조회 (삭제 예정 제외)
     */
    @Query("SELECT * FROM category WHERE syncStatus != 2 ORDER BY sortOrder ASC")
    List<Category> getAllCategories();

    @Query("SELECT * FROM category WHERE id = :id")
    Category getCategoryById(String id);

    /**
     * 카테고리 수 (삭제 예정 제외)
     */
    @Query("SELECT COUNT(*) FROM category WHERE syncStatus != 2")
    int getCategoryCount();

    @Query("SELECT MAX(sortOrder) FROM category WHERE syncStatus != 2")
    int getMaxSortOrder();

    /**
     * 기본 카테고리 조회 (삭제 예정 제외)
     */
    @Query("SELECT * FROM category WHERE isDefault = 1 AND syncStatus != 2")
    List<Category> getDefaultCategories();

    @Query("UPDATE category SET sortOrder = :sortOrder WHERE id = :id")
    void updateSortOrder(String id, int sortOrder);

    // ========== 동기화 관련 쿼리 ==========

    /**
     * 동기화가 필요한 카테고리 조회 (수정됨 또는 삭제 예정)
     */
    @Query("SELECT * FROM category WHERE syncStatus != 0 ORDER BY updatedAt ASC")
    List<Category> getUnsyncedCategories();

    /**
     * 동기화가 필요한 카테고리 수
     */
    @Query("SELECT COUNT(*) FROM category WHERE syncStatus != 0")
    int getUnsyncedCount();

    /**
     * 동기화 상태 업데이트
     */
    @Query("UPDATE category SET syncStatus = :status WHERE id = :id")
    void updateSyncStatus(String id, int status);

    /**
     * 모든 카테고리의 동기화 상태를 동기화됨으로 변경
     */
    @Query("UPDATE category SET syncStatus = 0 WHERE syncStatus = 1")
    void markAllSynced();

    /**
     * 삭제 예정 카테고리 영구 삭제
     */
    @Query("DELETE FROM category WHERE syncStatus = 2")
    void purgeDeleted();
}
