package com.example.assetinsight.data.local;

import androidx.annotation.NonNull;
import androidx.room.Entity;
import androidx.room.Index;
import androidx.room.PrimaryKey;

/**
 * 카테고리 엔티티
 * - 사용자 정의 자산 카테고리 관리
 */
@Entity(
    tableName = "category",
    indices = {
        @Index(value = {"syncStatus"})
    }
)
public class Category {

    @PrimaryKey
    @NonNull
    private String id;

    @NonNull
    private String name;

    private String icon; // 아이콘 리소스 이름

    private int sortOrder; // 정렬 순서

    private boolean isDefault; // 기본 카테고리 여부

    // 동기화 필드
    private long updatedAt; // 마지막 수정 시간 (epoch millis)
    private int syncStatus; // 0: 동기화됨, 1: 수정됨, 2: 삭제 예정

    public static final int SYNC_STATUS_SYNCED = 0;
    public static final int SYNC_STATUS_MODIFIED = 1;
    public static final int SYNC_STATUS_DELETED = 2;

    public Category(@NonNull String id, @NonNull String name, String icon, int sortOrder, boolean isDefault) {
        this.id = id;
        this.name = name;
        this.icon = icon;
        this.sortOrder = sortOrder;
        this.isDefault = isDefault;
        this.updatedAt = System.currentTimeMillis();
        this.syncStatus = SYNC_STATUS_MODIFIED;
    }

    @NonNull
    public String getId() {
        return id;
    }

    public void setId(@NonNull String id) {
        this.id = id;
    }

    @NonNull
    public String getName() {
        return name;
    }

    public void setName(@NonNull String name) {
        this.name = name;
    }

    public String getIcon() {
        return icon;
    }

    public void setIcon(String icon) {
        this.icon = icon;
    }

    public int getSortOrder() {
        return sortOrder;
    }

    public void setSortOrder(int sortOrder) {
        this.sortOrder = sortOrder;
    }

    public boolean isDefault() {
        return isDefault;
    }

    public void setDefault(boolean isDefault) {
        this.isDefault = isDefault;
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
