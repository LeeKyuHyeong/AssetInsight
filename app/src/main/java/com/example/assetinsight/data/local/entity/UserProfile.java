package com.example.assetinsight.data.local.entity;

import androidx.annotation.NonNull;
import androidx.room.Entity;
import androidx.room.Index;
import androidx.room.PrimaryKey;

/**
 * 사용자 프로필 엔티티
 * - 여러 계정을 로컬에 저장하여 프로필 전환 지원
 */
@Entity(
    tableName = "user_profile",
    indices = {
        @Index(value = {"isActive"})
    }
)
public class UserProfile {

    @PrimaryKey
    @NonNull
    private String id; // 서버에서 부여받은 userId

    @NonNull
    private String email;

    @NonNull
    private String name;

    @NonNull
    private String provider; // LOCAL, GOOGLE, KAKAO, NAVER

    private boolean isActive; // 현재 활성 프로필 여부

    private long lastSyncTime; // 마지막 동기화 시간 (epoch millis)

    private long createdAt; // 프로필 생성 시간

    public UserProfile(@NonNull String id, @NonNull String email, @NonNull String name,
                       @NonNull String provider, boolean isActive) {
        this.id = id;
        this.email = email;
        this.name = name;
        this.provider = provider;
        this.isActive = isActive;
        this.lastSyncTime = 0;
        this.createdAt = System.currentTimeMillis();
    }

    @NonNull
    public String getId() {
        return id;
    }

    public void setId(@NonNull String id) {
        this.id = id;
    }

    @NonNull
    public String getEmail() {
        return email;
    }

    public void setEmail(@NonNull String email) {
        this.email = email;
    }

    @NonNull
    public String getName() {
        return name;
    }

    public void setName(@NonNull String name) {
        this.name = name;
    }

    @NonNull
    public String getProvider() {
        return provider;
    }

    public void setProvider(@NonNull String provider) {
        this.provider = provider;
    }

    public boolean isActive() {
        return isActive;
    }

    public void setActive(boolean active) {
        isActive = active;
    }

    public long getLastSyncTime() {
        return lastSyncTime;
    }

    public void setLastSyncTime(long lastSyncTime) {
        this.lastSyncTime = lastSyncTime;
    }

    public long getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(long createdAt) {
        this.createdAt = createdAt;
    }
}
