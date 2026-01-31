package com.example.assetinsight.service;

import android.content.Context;

import androidx.annotation.NonNull;
import androidx.work.Constraints;
import androidx.work.ExistingPeriodicWorkPolicy;
import androidx.work.ExistingWorkPolicy;
import androidx.work.NetworkType;
import androidx.work.OneTimeWorkRequest;
import androidx.work.PeriodicWorkRequest;
import androidx.work.WorkManager;
import androidx.work.Worker;
import androidx.work.WorkerParameters;

import com.example.assetinsight.data.local.AppDatabase;
import com.example.assetinsight.data.remote.ApiClient;
import com.example.assetinsight.data.remote.TokenManager;
import com.example.assetinsight.data.repository.SyncRepository;
import com.example.assetinsight.util.DatabaseKeyManager;

import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;

import timber.log.Timber;

/**
 * 백그라운드 동기화 Worker
 */
public class SyncWorker extends Worker {

    public static final String WORK_NAME_PERIODIC = "sync_periodic";
    public static final String WORK_NAME_ONE_TIME = "sync_one_time";

    public SyncWorker(@NonNull Context context, @NonNull WorkerParameters workerParams) {
        super(context, workerParams);
    }

    @NonNull
    @Override
    public Result doWork() {
        Timber.d("SyncWorker started");

        TokenManager tokenManager = ApiClient.getInstance(getApplicationContext()).getTokenManager();

        // 로그인 상태가 아니면 스킵
        if (!tokenManager.isLoggedIn()) {
            Timber.d("Not logged in, skipping sync");
            return Result.success();
        }

        try {
            AppDatabase database = AppDatabase.getInstance(
                    getApplicationContext(),
                    DatabaseKeyManager.getKey()
            );

            SyncRepository syncRepository = new SyncRepository(getApplicationContext(), database);

            CountDownLatch latch = new CountDownLatch(1);
            AtomicBoolean success = new AtomicBoolean(false);

            syncRepository.sync(new SyncRepository.SyncCallback() {
                @Override
                public void onSuccess() {
                    Timber.d("SyncWorker completed successfully");
                    success.set(true);
                    latch.countDown();
                }

                @Override
                public void onError(String message) {
                    Timber.e("SyncWorker failed: %s", message);
                    latch.countDown();
                }
            });

            // 최대 2분 대기
            boolean completed = latch.await(2, TimeUnit.MINUTES);

            if (!completed) {
                Timber.w("SyncWorker timeout");
                return Result.retry();
            }

            return success.get() ? Result.success() : Result.retry();

        } catch (Exception e) {
            Timber.e(e, "SyncWorker exception");
            return Result.retry();
        }
    }

    /**
     * 즉시 동기화 요청
     */
    public static void enqueueOneTime(Context context) {
        Constraints constraints = new Constraints.Builder()
                .setRequiredNetworkType(NetworkType.CONNECTED)
                .build();

        OneTimeWorkRequest workRequest = new OneTimeWorkRequest.Builder(SyncWorker.class)
                .setConstraints(constraints)
                .build();

        WorkManager.getInstance(context)
                .enqueueUniqueWork(WORK_NAME_ONE_TIME, ExistingWorkPolicy.REPLACE, workRequest);

        Timber.d("One-time sync work enqueued");
    }

    /**
     * 주기적 동기화 설정 (15분 간격)
     */
    public static void enqueuePeriodicSync(Context context) {
        Constraints constraints = new Constraints.Builder()
                .setRequiredNetworkType(NetworkType.CONNECTED)
                .build();

        PeriodicWorkRequest workRequest = new PeriodicWorkRequest.Builder(
                SyncWorker.class,
                15, TimeUnit.MINUTES
        )
                .setConstraints(constraints)
                .build();

        WorkManager.getInstance(context)
                .enqueueUniquePeriodicWork(
                        WORK_NAME_PERIODIC,
                        ExistingPeriodicWorkPolicy.KEEP,
                        workRequest
                );

        Timber.d("Periodic sync work enqueued");
    }

    /**
     * 주기적 동기화 취소
     */
    public static void cancelPeriodicSync(Context context) {
        WorkManager.getInstance(context).cancelUniqueWork(WORK_NAME_PERIODIC);
        Timber.d("Periodic sync work cancelled");
    }
}
