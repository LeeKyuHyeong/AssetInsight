package com.example.assetinsight.data.local;

import androidx.annotation.NonNull;
import androidx.room.Entity;
import androidx.room.Index;

/**
 * 자산 스냅샷 엔티티
 * - 날짜별 각 카테고리의 자산 금액을 기록
 * - Composite Primary Key: date + categoryId
 */
@Entity(
    tableName = "asset_snapshot",
    primaryKeys = {"date", "categoryId"},
    indices = {
        @Index(value = {"categoryId", "date"}),
        @Index(value = {"syncStatus"})
    }
)
public class AssetSnapshot {

    @NonNull
    private String date; // yyyy-MM-dd 형식

    @NonNull
    private String categoryId;

    private long amount;

    private String memo;

    // 동기화 필드
    private long updatedAt; // 마지막 수정 시간 (epoch millis)
    private int syncStatus; // 0: 동기화됨, 1: 수정됨, 2: 삭제 예정

    public static final int SYNC_STATUS_SYNCED = 0;
    public static final int SYNC_STATUS_MODIFIED = 1;
    public static final int SYNC_STATUS_DELETED = 2;

    public AssetSnapshot(@NonNull String date, @NonNull String categoryId, long amount, String memo) {
        this.date = date;
        this.categoryId = categoryId;
        this.amount = amount;
        this.memo = memo;
        this.updatedAt = System.currentTimeMillis();
        this.syncStatus = SYNC_STATUS_MODIFIED;
    }

    @NonNull
    public String getDate() {
        return date;
    }

    public void setDate(@NonNull String date) {
        this.date = date;
    }

    @NonNull
    public String getCategoryId() {
        return categoryId;
    }

    public void setCategoryId(@NonNull String categoryId) {
        this.categoryId = categoryId;
    }

    public long getAmount() {
        return amount;
    }

    public void setAmount(long amount) {
        this.amount = amount;
    }

    public String getMemo() {
        return memo;
    }

    public void setMemo(String memo) {
        this.memo = memo;
    }

    public long getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(long updatedAt) {
        this.updatedAt = updatedAt;
    }

    public int getSyncStatus() {
        return syncStatus;
    }

    public void setSyncStatus(int syncStatus) {
        this.syncStatus = syncStatus;
    }

    /**
     * 수정 시 호출하여 타임스탬프와 동기화 상태 업데이트
     */
    public void markModified() {
        this.updatedAt = System.currentTimeMillis();
        this.syncStatus = SYNC_STATUS_MODIFIED;
    }

    /**
     * 삭제 표시 (soft delete)
     */
    public void markDeleted() {
        this.updatedAt = System.currentTimeMillis();
        this.syncStatus = SYNC_STATUS_DELETED;
    }

    /**
     * 동기화 완료 표시
     */
    public void markSynced() {
        this.syncStatus = SYNC_STATUS_SYNCED;
    }
}
