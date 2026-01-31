package com.example.assetinsight.data.remote.dto;

import com.google.gson.annotations.SerializedName;

import java.util.List;

public class SyncDto {

    // ========== Request DTOs ==========

    public static class PullRequest {
        @SerializedName("lastSyncTime")
        public Long lastSyncTime;

        public PullRequest(Long lastSyncTime) {
            this.lastSyncTime = lastSyncTime;
        }
    }

    public static class PushRequest {
        @SerializedName("snapshots")
        public List<AssetSnapshotDto> snapshots;

        @SerializedName("categories")
        public List<CategoryDto> categories;

        public PushRequest(List<AssetSnapshotDto> snapshots, List<CategoryDto> categories) {
            this.snapshots = snapshots;
            this.categories = categories;
        }
    }

    // ========== Response DTOs ==========

    public static class SyncResponse {
        @SerializedName("serverTime")
        public Long serverTime;

        @SerializedName("snapshots")
        public List<AssetSnapshotDto> snapshots;

        @SerializedName("categories")
        public List<CategoryDto> categories;
    }

    // ========== Common DTOs ==========

    public static class AssetSnapshotDto {
        @SerializedName("date")
        public String date;

        @SerializedName("categoryId")
        public String categoryId;

        @SerializedName("amount")
        public Long amount;

        @SerializedName("memo")
        public String memo;

        @SerializedName("updatedAt")
        public Long updatedAt;

        @SerializedName("deleted")
        public boolean deleted;

        public AssetSnapshotDto() {}

        public AssetSnapshotDto(String date, String categoryId, Long amount, String memo,
                                Long updatedAt, boolean deleted) {
            this.date = date;
            this.categoryId = categoryId;
            this.amount = amount;
            this.memo = memo;
            this.updatedAt = updatedAt;
            this.deleted = deleted;
        }
    }

    public static class CategoryDto {
        @SerializedName("id")
        public String id;

        @SerializedName("name")
        public String name;

        @SerializedName("icon")
        public String icon;

        @SerializedName("sortOrder")
        public Integer sortOrder;

        @SerializedName("isDefault")
        public Boolean isDefault;

        @SerializedName("updatedAt")
        public Long updatedAt;

        @SerializedName("deleted")
        public boolean deleted;

        public CategoryDto() {}

        public CategoryDto(String id, String name, String icon, Integer sortOrder,
                           Boolean isDefault, Long updatedAt, boolean deleted) {
            this.id = id;
            this.name = name;
            this.icon = icon;
            this.sortOrder = sortOrder;
            this.isDefault = isDefault;
            this.updatedAt = updatedAt;
            this.deleted = deleted;
        }
    }
}
