package com.example.assetinsight.data.local;

import android.content.Context;

import androidx.annotation.NonNull;
import androidx.room.Database;
import androidx.room.Room;
import androidx.room.RoomDatabase;
import androidx.room.migration.Migration;
import androidx.sqlite.db.SupportSQLiteDatabase;

import com.example.assetinsight.data.local.dao.UserProfileDao;
import com.example.assetinsight.data.local.entity.UserProfile;

import net.sqlcipher.database.SupportFactory;

import java.util.Arrays;
import java.util.List;
import java.util.concurrent.Executors;

/**
 * Room Database with SQLCipher 암호화
 */
@Database(
    entities = {AssetSnapshot.class, Category.class, UserProfile.class},
    version = 3,
    exportSchema = false
)
public abstract class AppDatabase extends RoomDatabase {

    private static volatile AppDatabase INSTANCE;
    private static final String DATABASE_NAME = "asset_insight.db";

    public abstract AssetSnapshotDao assetSnapshotDao();
    public abstract CategoryDao categoryDao();
    public abstract UserProfileDao userProfileDao();

    // 버전 1 -> 2 마이그레이션 (Category 테이블 추가)
    static final Migration MIGRATION_1_2 = new Migration(1, 2) {
        @Override
        public void migrate(@NonNull SupportSQLiteDatabase database) {
            database.execSQL("CREATE TABLE IF NOT EXISTS `category` (" +
                    "`id` TEXT NOT NULL, " +
                    "`name` TEXT NOT NULL, " +
                    "`icon` TEXT, " +
                    "`sortOrder` INTEGER NOT NULL, " +
                    "`isDefault` INTEGER NOT NULL, " +
                    "PRIMARY KEY(`id`))");
        }
    };

    // 버전 2 -> 3 마이그레이션 (동기화 필드 추가 + UserProfile 테이블)
    static final Migration MIGRATION_2_3 = new Migration(2, 3) {
        @Override
        public void migrate(@NonNull SupportSQLiteDatabase database) {
            // AssetSnapshot에 동기화 필드 추가
            database.execSQL("ALTER TABLE asset_snapshot ADD COLUMN updatedAt INTEGER NOT NULL DEFAULT 0");
            database.execSQL("ALTER TABLE asset_snapshot ADD COLUMN syncStatus INTEGER NOT NULL DEFAULT 0");
            database.execSQL("CREATE INDEX IF NOT EXISTS index_asset_snapshot_syncStatus ON asset_snapshot(syncStatus)");

            // Category에 동기화 필드 추가
            database.execSQL("ALTER TABLE category ADD COLUMN updatedAt INTEGER NOT NULL DEFAULT 0");
            database.execSQL("ALTER TABLE category ADD COLUMN syncStatus INTEGER NOT NULL DEFAULT 0");
            database.execSQL("CREATE INDEX IF NOT EXISTS index_category_syncStatus ON category(syncStatus)");

            // UserProfile 테이블 생성
            database.execSQL("CREATE TABLE IF NOT EXISTS `user_profile` (" +
                    "`id` TEXT NOT NULL, " +
                    "`email` TEXT NOT NULL, " +
                    "`name` TEXT NOT NULL, " +
                    "`provider` TEXT NOT NULL, " +
                    "`isActive` INTEGER NOT NULL, " +
                    "`lastSyncTime` INTEGER NOT NULL, " +
                    "`createdAt` INTEGER NOT NULL, " +
                    "PRIMARY KEY(`id`))");
            database.execSQL("CREATE INDEX IF NOT EXISTS index_user_profile_isActive ON user_profile(isActive)");

            // 기존 데이터의 updatedAt 초기화 (현재 시간으로)
            long now = System.currentTimeMillis();
            database.execSQL("UPDATE asset_snapshot SET updatedAt = " + now + " WHERE updatedAt = 0");
            database.execSQL("UPDATE category SET updatedAt = " + now + " WHERE updatedAt = 0");
        }
    };

    /**
     * 암호화된 데이터베이스 인스턴스 반환
     * @param context Application Context
     * @param passphrase DB 암호화 키 (BiometricPrompt 또는 KeyStore에서 관리)
     */
    public static AppDatabase getInstance(Context context, char[] passphrase) {
        if (INSTANCE == null) {
            synchronized (AppDatabase.class) {
                if (INSTANCE == null) {
                    Context appContext = context.getApplicationContext();
                    boolean isDebug = (appContext.getApplicationInfo().flags
                            & android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) != 0;

                    RoomDatabase.Builder<AppDatabase> builder = Room.databaseBuilder(
                            appContext,
                            AppDatabase.class,
                            DATABASE_NAME
                    );

                    if (isDebug) {
                        // Debug 빌드: 암호화 없이 일반 SQLite 사용
                        // 기존 암호화된 DB가 있으면 삭제
                        SQLCipherUtils.DbState dbState = SQLCipherUtils.getDatabaseState(appContext, DATABASE_NAME);
                        if (dbState == SQLCipherUtils.DbState.ENCRYPTED) {
                            SQLCipherUtils.deleteDatabase(appContext, DATABASE_NAME);
                        }
                    } else {
                        // Release 빌드: SQLCipher 암호화 사용
                        SQLCipherUtils.DbState dbState = SQLCipherUtils.getDatabaseState(appContext, DATABASE_NAME);
                        if (dbState == SQLCipherUtils.DbState.UNENCRYPTED) {
                            SQLCipherUtils.deleteDatabase(appContext, DATABASE_NAME);
                        }
                        SupportFactory factory = new SupportFactory(SQLCipherUtils.getKey(passphrase));
                        builder.openHelperFactory(factory);
                    }

                    INSTANCE = builder
                            .addMigrations(MIGRATION_1_2, MIGRATION_2_3)
                            .addCallback(new Callback() {
                                @Override
                                public void onCreate(@NonNull SupportSQLiteDatabase db) {
                                    super.onCreate(db);
                                    // 기본 카테고리 초기화
                                    Executors.newSingleThreadExecutor().execute(() -> {
                                        insertDefaultCategories(INSTANCE);
                                    });
                                }
                            })
                            .build();
                }
            }
        }
        return INSTANCE;
    }

    /**
     * 기본 카테고리 초기화
     */
    private static void insertDefaultCategories(AppDatabase db) {
        List<Category> defaultCategories = Arrays.asList(
                new Category("cash", "현금", "ic_category_cash", 0, true),
                new Category("bank", "은행 예금", "ic_category_bank", 1, true),
                new Category("stock", "주식", "ic_category_stock", 2, true),
                new Category("fund", "펀드", "ic_category_fund", 3, true),
                new Category("real_estate", "부동산", "ic_category_real_estate", 4, true),
                new Category("crypto", "암호화폐", "ic_category_crypto", 5, true),
                new Category("other", "기타", "ic_category_other", 6, true)
        );
        // 기본 카테고리는 동기화 상태를 SYNCED로 설정
        for (Category category : defaultCategories) {
            category.setSyncStatus(Category.SYNC_STATUS_SYNCED);
        }
        db.categoryDao().insertAll(defaultCategories);
    }

    /**
     * 기본 카테고리가 없으면 초기화 (마이그레이션 후 호출용)
     */
    public void ensureDefaultCategories() {
        Executors.newSingleThreadExecutor().execute(() -> {
            if (categoryDao().getCategoryCount() == 0) {
                insertDefaultCategories(this);
            }
        });
    }

    /**
     * 프로필 전환 시 로컬 데이터 초기화
     */
    public void clearLocalData() {
        Executors.newSingleThreadExecutor().execute(() -> {
            assetSnapshotDao().deleteAll();
            categoryDao().deleteAll();
        });
    }

    /**
     * 데이터베이스 인스턴스 해제 (암호 변경 등의 경우)
     */
    public static void destroyInstance() {
        if (INSTANCE != null && INSTANCE.isOpen()) {
            INSTANCE.close();
        }
        INSTANCE = null;
    }
}
