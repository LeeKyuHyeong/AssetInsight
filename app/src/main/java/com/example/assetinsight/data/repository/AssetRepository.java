package com.example.assetinsight.data.repository;

import android.content.Context;

import com.example.assetinsight.data.local.AppDatabase;
import com.example.assetinsight.data.local.AssetSnapshot;
import com.example.assetinsight.data.local.AssetSnapshotDao;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * 자산 데이터 Repository
 * - 데이터 소스 결정 및 비즈니스 로직 중재
 * - 비동기 처리를 위한 ExecutorService 활용
 * - 동기화 지원: 저장/삭제 시 syncStatus 자동 설정
 */
public class AssetRepository {

    private final AssetSnapshotDao dao;
    private final ExecutorService executor;

    public AssetRepository(Context context, char[] passphrase) {
        AppDatabase db = AppDatabase.getInstance(context, passphrase);
        this.dao = db.assetSnapshotDao();
        this.executor = Executors.newSingleThreadExecutor();
    }

    /**
     * 스냅샷 저장 (비동기)
     * 저장 시 syncStatus를 MODIFIED로 설정
     */
    public void saveSnapshot(AssetSnapshot snapshot, Runnable onComplete) {
        executor.execute(() -> {
            snapshot.markModified();
            dao.upsert(snapshot);
            if (onComplete != null) {
                onComplete.run();
            }
        });
    }

    /**
     * 여러 스냅샷 일괄 저장 (비동기)
     */
    public void saveSnapshots(List<AssetSnapshot> snapshots, Runnable onComplete) {
        executor.execute(() -> {
            for (AssetSnapshot snapshot : snapshots) {
                snapshot.markModified();
            }
            dao.upsertAll(snapshots);
            if (onComplete != null) {
                onComplete.run();
            }
        });
    }

    /**
     * 특정 날짜의 스냅샷 조회 (콜백)
     */
    public void getSnapshotsByDate(String date, DataCallback<List<AssetSnapshot>> callback) {
        executor.execute(() -> {
            List<AssetSnapshot> result = dao.getSnapshotsByDate(date);
            callback.onResult(result);
        });
    }

    /**
     * 특정 카테고리의 특정 시점 또는 가장 가까운 과거 데이터 조회
     */
    public void getClosestSnapshot(String categoryId, String targetDate,
                                   DataCallback<AssetSnapshot> callback) {
        executor.execute(() -> {
            AssetSnapshot result = dao.getClosestSnapshot(categoryId, targetDate);
            callback.onResult(result);
        });
    }

    /**
     * 특정 날짜 기준 전체 자산 총액 조회
     * 각 카테고리별로 targetDate 이전의 가장 최신 데이터를 찾아 합산
     */
    public void getTotalAmountAtDate(String targetDate, DataCallback<Long> callback) {
        executor.execute(() -> {
            List<AssetSnapshot> allSnapshots = dao.getAllSnapshots();

            // 각 카테고리별로 targetDate 이전의 가장 최신 스냅샷 찾기
            Map<String, AssetSnapshot> latestByCategory = new HashMap<>();

            for (AssetSnapshot snapshot : allSnapshots) {
                if (snapshot.getDate().compareTo(targetDate) <= 0) {
                    String categoryId = snapshot.getCategoryId();
                    AssetSnapshot existing = latestByCategory.get(categoryId);

                    if (existing == null || snapshot.getDate().compareTo(existing.getDate()) > 0) {
                        latestByCategory.put(categoryId, snapshot);
                    }
                }
            }

            // 합산
            long total = 0;
            for (AssetSnapshot snapshot : latestByCategory.values()) {
                total += snapshot.getAmount();
            }

            callback.onResult(total);
        });
    }

    /**
     * 모든 카테고리 ID 조회 (스냅샷에 있는 카테고리)
     */
    public void getAllCategoryIds(DataCallback<List<String>> callback) {
        executor.execute(() -> {
            List<AssetSnapshot> allSnapshots = dao.getAllSnapshots();

            // 중복 제거하여 카테고리 ID 추출
            Map<String, Boolean> categoryMap = new HashMap<>();
            for (AssetSnapshot snapshot : allSnapshots) {
                categoryMap.put(snapshot.getCategoryId(), true);
            }

            List<String> result = new java.util.ArrayList<>(categoryMap.keySet());
            callback.onResult(result);
        });
    }

    /**
     * 특정 카테고리의 모든 기록 조회
     */
    public void getSnapshotsByCategory(String categoryId, DataCallback<List<AssetSnapshot>> callback) {
        executor.execute(() -> {
            List<AssetSnapshot> result = dao.getSnapshotsByCategory(categoryId);
            callback.onResult(result);
        });
    }

    /**
     * 모든 스냅샷 조회
     */
    public void getAllSnapshots(DataCallback<List<AssetSnapshot>> callback) {
        executor.execute(() -> {
            List<AssetSnapshot> result = dao.getAllSnapshots();
            callback.onResult(result);
        });
    }

    /**
     * 스냅샷 삭제 (soft delete for sync)
     * 동기화 지원: 삭제 대신 DELETED 상태로 표시
     */
    public void deleteSnapshot(String date, String categoryId, Runnable onComplete) {
        executor.execute(() -> {
            AssetSnapshot existing = dao.getSnapshot(date, categoryId);
            if (existing != null) {
                existing.markDeleted();
                dao.upsert(existing);
            }
            if (onComplete != null) {
                onComplete.run();
            }
        });
    }

    /**
     * 스냅샷 영구 삭제 (hard delete)
     * 동기화 없이 즉시 삭제가 필요한 경우
     */
    public void deleteSnapshotPermanently(String date, String categoryId, Runnable onComplete) {
        executor.execute(() -> {
            dao.delete(date, categoryId);
            if (onComplete != null) {
                onComplete.run();
            }
        });
    }

    /**
     * 비동기 결과 콜백 인터페이스
     */
    public interface DataCallback<T> {
        void onResult(T result);
    }
}
