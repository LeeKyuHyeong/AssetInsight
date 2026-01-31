package com.example.assetinsight.data.repository;

import android.content.Context;

import androidx.annotation.NonNull;

import com.example.assetinsight.data.local.AppDatabase;
import com.example.assetinsight.data.local.AssetSnapshot;
import com.example.assetinsight.data.local.Category;
import com.example.assetinsight.data.local.entity.UserProfile;
import com.example.assetinsight.data.remote.ApiClient;
import com.example.assetinsight.data.remote.TokenManager;
import com.example.assetinsight.data.remote.api.SyncApi;
import com.example.assetinsight.data.remote.dto.ApiResponse;
import com.example.assetinsight.data.remote.dto.SyncDto;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;
import timber.log.Timber;

/**
 * 동기화 Repository
 */
public class SyncRepository {

    private final SyncApi syncApi;
    private final TokenManager tokenManager;
    private final AppDatabase database;
    private final AuthRepository authRepository;
    private final ExecutorService executor;

    public interface SyncCallback {
        void onSuccess();
        void onError(String message);
    }

    public SyncRepository(Context context, AppDatabase database) {
        ApiClient apiClient = ApiClient.getInstance(context);
        this.syncApi = apiClient.getSyncApi();
        this.tokenManager = apiClient.getTokenManager();
        this.database = database;
        this.authRepository = new AuthRepository(context, database);
        this.executor = Executors.newSingleThreadExecutor();
    }

    /**
     * 전체 동기화 (Pull -> Push)
     */
    public void sync(SyncCallback callback) {
        if (!tokenManager.isLoggedIn()) {
            callback.onError("로그인이 필요합니다");
            return;
        }

        // 토큰 만료 시 갱신 시도
        if (tokenManager.isTokenExpired()) {
            if (!authRepository.refreshTokenSync()) {
                callback.onError("세션이 만료되었습니다. 다시 로그인해주세요.");
                return;
            }
        }

        executor.execute(() -> {
            try {
                // 1. Pull (서버 -> 로컬)
                pullSync();

                // 2. Push (로컬 -> 서버)
                pushSync();

                // 3. 마지막 동기화 시간 업데이트
                String userId = tokenManager.getUserId();
                if (userId != null) {
                    database.userProfileDao().updateLastSyncTime(userId, System.currentTimeMillis());
                }

                callback.onSuccess();
            } catch (Exception e) {
                Timber.e(e, "Sync failed");
                callback.onError("동기화 실패: " + e.getMessage());
            }
        });
    }

    /**
     * Pull 동기화 (서버 -> 로컬)
     */
    private void pullSync() throws IOException {
        String userId = tokenManager.getUserId();
        if (userId == null) return;

        // 마지막 동기화 시간 조회
        UserProfile profile = database.userProfileDao().getById(userId);
        Long lastSyncTime = profile != null ? profile.getLastSyncTime() : null;

        SyncDto.PullRequest request = new SyncDto.PullRequest(lastSyncTime);
        Response<ApiResponse<SyncDto.SyncResponse>> response = syncApi.pull(request).execute();

        if (!response.isSuccessful() || response.body() == null || !response.body().isSuccess()) {
            throw new IOException("Pull sync failed: " + getErrorMessage(response));
        }

        SyncDto.SyncResponse syncData = response.body().getData();
        if (syncData == null) return;

        // 서버 데이터를 로컬에 반영
        applyPullData(syncData);

        Timber.d("Pull sync completed: %d snapshots, %d categories",
                syncData.snapshots != null ? syncData.snapshots.size() : 0,
                syncData.categories != null ? syncData.categories.size() : 0);
    }

    /**
     * Push 동기화 (로컬 -> 서버)
     */
    private void pushSync() throws IOException {
        // 동기화가 필요한 로컬 데이터 조회
        List<AssetSnapshot> unsyncedSnapshots = database.assetSnapshotDao().getUnsyncedSnapshots();
        List<Category> unsyncedCategories = database.categoryDao().getUnsyncedCategories();

        if (unsyncedSnapshots.isEmpty() && unsyncedCategories.isEmpty()) {
            Timber.d("No unsynced data to push");
            return;
        }

        // DTO 변환
        List<SyncDto.AssetSnapshotDto> snapshotDtos = new ArrayList<>();
        for (AssetSnapshot snapshot : unsyncedSnapshots) {
            snapshotDtos.add(new SyncDto.AssetSnapshotDto(
                    snapshot.getDate(),
                    snapshot.getCategoryId(),
                    snapshot.getAmount(),
                    snapshot.getMemo(),
                    snapshot.getUpdatedAt(),
                    snapshot.getSyncStatus() == AssetSnapshot.SYNC_STATUS_DELETED
            ));
        }

        List<SyncDto.CategoryDto> categoryDtos = new ArrayList<>();
        for (Category category : unsyncedCategories) {
            categoryDtos.add(new SyncDto.CategoryDto(
                    category.getId(),
                    category.getName(),
                    category.getIcon(),
                    category.getSortOrder(),
                    category.isDefault(),
                    category.getUpdatedAt(),
                    category.getSyncStatus() == Category.SYNC_STATUS_DELETED
            ));
        }

        SyncDto.PushRequest request = new SyncDto.PushRequest(snapshotDtos, categoryDtos);
        Response<ApiResponse<SyncDto.SyncResponse>> response = syncApi.push(request).execute();

        if (!response.isSuccessful() || response.body() == null || !response.body().isSuccess()) {
            throw new IOException("Push sync failed: " + getErrorMessage(response));
        }

        // 푸시 성공 후 로컬 상태 업데이트
        database.assetSnapshotDao().markAllSynced();
        database.assetSnapshotDao().purgeDeleted();
        database.categoryDao().markAllSynced();
        database.categoryDao().purgeDeleted();

        Timber.d("Push sync completed: %d snapshots, %d categories",
                snapshotDtos.size(), categoryDtos.size());
    }

    /**
     * Pull 데이터를 로컬에 반영
     */
    private void applyPullData(SyncDto.SyncResponse syncData) {
        // 카테고리 반영
        if (syncData.categories != null) {
            for (SyncDto.CategoryDto dto : syncData.categories) {
                Category existing = database.categoryDao().getCategoryById(dto.id);

                if (dto.deleted) {
                    // 서버에서 삭제됨
                    if (existing != null) {
                        database.categoryDao().deleteById(dto.id);
                    }
                } else {
                    // Last-Write-Wins: 서버 데이터가 더 최신이면 반영
                    if (existing == null || existing.getUpdatedAt() < dto.updatedAt) {
                        Category category = new Category(
                                dto.id, dto.name, dto.icon,
                                dto.sortOrder != null ? dto.sortOrder : 0,
                                dto.isDefault != null && dto.isDefault
                        );
                        category.setUpdatedAt(dto.updatedAt);
                        category.setSyncStatus(Category.SYNC_STATUS_SYNCED);
                        database.categoryDao().insert(category);
                    }
                }
            }
        }

        // 스냅샷 반영
        if (syncData.snapshots != null) {
            for (SyncDto.AssetSnapshotDto dto : syncData.snapshots) {
                AssetSnapshot existing = database.assetSnapshotDao().getSnapshot(dto.date, dto.categoryId);

                if (dto.deleted) {
                    // 서버에서 삭제됨
                    if (existing != null) {
                        database.assetSnapshotDao().delete(dto.date, dto.categoryId);
                    }
                } else {
                    // Last-Write-Wins
                    if (existing == null || existing.getUpdatedAt() < dto.updatedAt) {
                        AssetSnapshot snapshot = new AssetSnapshot(
                                dto.date, dto.categoryId, dto.amount, dto.memo
                        );
                        snapshot.setUpdatedAt(dto.updatedAt);
                        snapshot.setSyncStatus(AssetSnapshot.SYNC_STATUS_SYNCED);
                        database.assetSnapshotDao().upsert(snapshot);
                    }
                }
            }
        }
    }

    /**
     * 비동기 Pull 동기화
     */
    public void pullAsync(SyncCallback callback) {
        if (!tokenManager.isLoggedIn()) {
            callback.onError("로그인이 필요합니다");
            return;
        }

        executor.execute(() -> {
            try {
                pullSync();
                callback.onSuccess();
            } catch (Exception e) {
                Timber.e(e, "Pull sync failed");
                callback.onError("동기화 실패: " + e.getMessage());
            }
        });
    }

    /**
     * 비동기 Push 동기화
     */
    public void pushAsync(SyncCallback callback) {
        if (!tokenManager.isLoggedIn()) {
            callback.onError("로그인이 필요합니다");
            return;
        }

        executor.execute(() -> {
            try {
                pushSync();
                callback.onSuccess();
            } catch (Exception e) {
                Timber.e(e, "Push sync failed");
                callback.onError("동기화 실패: " + e.getMessage());
            }
        });
    }

    /**
     * 동기화 대기 중인 항목 수 조회
     */
    public int getUnsyncedCount() {
        return database.assetSnapshotDao().getUnsyncedCount() +
                database.categoryDao().getUnsyncedCount();
    }

    private String getErrorMessage(Response<?> response) {
        if (response.errorBody() != null) {
            try {
                return response.errorBody().string();
            } catch (IOException e) {
                return "Unknown error";
            }
        }
        return "Unknown error";
    }
}
