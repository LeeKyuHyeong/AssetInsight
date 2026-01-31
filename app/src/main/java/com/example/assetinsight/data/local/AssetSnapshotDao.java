package com.example.assetinsight.data.local;

import androidx.room.Dao;
import androidx.room.Insert;
import androidx.room.OnConflictStrategy;
import androidx.room.Query;

import java.util.List;

/**
 * 자산 스냅샷 DAO
 * - UPSERT 전략: 동일 날짜+카테고리 입력 시 덮어쓰기
 */
@Dao
public interface AssetSnapshotDao {

    /**
     * 스냅샷 저장 (UPSERT)
     * 동일한 date + categoryId가 존재하면 덮어쓰기
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    void upsert(AssetSnapshot snapshot);

    /**
     * 여러 스냅샷 일괄 저장
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    void upsertAll(List<AssetSnapshot> snapshots);

    /**
     * 특정 날짜의 모든 카테고리 스냅샷 조회 (삭제 예정 제외)
     */
    @Query("SELECT * FROM asset_snapshot WHERE date = :date AND syncStatus != 2")
    List<AssetSnapshot> getSnapshotsByDate(String date);

    /**
     * 특정 카테고리의 특정 날짜 또는 가장 가까운 과거 데이터 조회
     * (데이터 보간 로직의 핵심 쿼리, 삭제 예정 제외)
     */
    @Query("SELECT * FROM asset_snapshot " +
           "WHERE categoryId = :categoryId AND date <= :targetDate AND syncStatus != 2 " +
           "ORDER BY date DESC LIMIT 1")
    AssetSnapshot getClosestSnapshot(String categoryId, String targetDate);

    /**
     * 특정 날짜 기준 모든 카테고리의 가장 가까운 과거 금액 합계
     * (전체 자산 총액 계산용, 삭제 예정 제외)
     */
    @Query("SELECT SUM(amount) FROM asset_snapshot a " +
           "WHERE syncStatus != 2 AND date = (SELECT MAX(date) FROM asset_snapshot b " +
           "WHERE b.categoryId = a.categoryId AND b.date <= :targetDate AND b.syncStatus != 2)")
    Long getTotalAmountAtDate(String targetDate);

    /**
     * 특정 카테고리의 모든 기록 조회 (날짜순, 삭제 예정 제외)
     */
    @Query("SELECT * FROM asset_snapshot WHERE categoryId = :categoryId AND syncStatus != 2 ORDER BY date ASC")
    List<AssetSnapshot> getSnapshotsByCategory(String categoryId);

    /**
     * 모든 스냅샷 조회 (삭제 예정 제외)
     */
    @Query("SELECT * FROM asset_snapshot WHERE syncStatus != 2 ORDER BY date DESC, categoryId ASC")
    List<AssetSnapshot> getAllSnapshots();

    /**
     * 특정 스냅샷 삭제
     */
    @Query("DELETE FROM asset_snapshot WHERE date = :date AND categoryId = :categoryId")
    void delete(String date, String categoryId);

    /**
     * 모든 스냅샷 삭제
     */
    @Query("DELETE FROM asset_snapshot")
    void deleteAll();

    /**
     * 특정 카테고리의 모든 스냅샷 삭제
     */
    @Query("DELETE FROM asset_snapshot WHERE categoryId = :categoryId")
    void deleteByCategory(String categoryId);

    /**
     * 등록된 카테고리 ID 목록 조회 (중복 제거, 삭제 예정 제외)
     */
    @Query("SELECT DISTINCT categoryId FROM asset_snapshot WHERE syncStatus != 2 ORDER BY categoryId")
    List<String> getAllCategoryIds();

    // ========== 동기화 관련 쿼리 ==========

    /**
     * 동기화가 필요한 스냅샷 조회 (수정됨 또는 삭제 예정)
     */
    @Query("SELECT * FROM asset_snapshot WHERE syncStatus != 0 ORDER BY updatedAt ASC")
    List<AssetSnapshot> getUnsyncedSnapshots();

    /**
     * 동기화가 필요한 스냅샷 수
     */
    @Query("SELECT COUNT(*) FROM asset_snapshot WHERE syncStatus != 0")
    int getUnsyncedCount();

    /**
     * 동기화 상태 업데이트
     */
    @Query("UPDATE asset_snapshot SET syncStatus = :status WHERE date = :date AND categoryId = :categoryId")
    void updateSyncStatus(String date, String categoryId, int status);

    /**
     * 모든 스냅샷의 동기화 상태를 동기화됨으로 변경
     */
    @Query("UPDATE asset_snapshot SET syncStatus = 0 WHERE syncStatus = 1")
    void markAllSynced();

    /**
     * 삭제 예정 스냅샷 영구 삭제
     */
    @Query("DELETE FROM asset_snapshot WHERE syncStatus = 2")
    void purgeDeleted();

    /**
     * 특정 스냅샷 조회
     */
    @Query("SELECT * FROM asset_snapshot WHERE date = :date AND categoryId = :categoryId")
    AssetSnapshot getSnapshot(String date, String categoryId);
}
