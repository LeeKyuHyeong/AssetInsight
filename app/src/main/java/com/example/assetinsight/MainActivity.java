package com.example.assetinsight;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.Toast;

import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;

import com.example.assetinsight.data.local.AppDatabase;
import com.example.assetinsight.data.remote.ApiClient;
import com.example.assetinsight.data.remote.TokenManager;
import com.example.assetinsight.data.repository.SyncRepository;
import com.example.assetinsight.databinding.ActivityMainBinding;
import com.example.assetinsight.service.SyncWorker;
import com.example.assetinsight.ui.auth.LoginActivity;
import com.example.assetinsight.ui.input.InputActivity;
import com.example.assetinsight.util.DatabaseKeyManager;
import com.example.assetinsight.util.PreferenceManager;
import com.example.assetinsight.util.SecurityHelper;
import com.example.assetinsight.util.SecurityHelper.BiometricStatus;

public class MainActivity extends AppCompatActivity {

    private ActivityMainBinding binding;
    private SecurityHelper securityHelper;
    private PreferenceManager prefManager;
    private TokenManager tokenManager;
    private boolean isAuthenticated = false;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        prefManager = new PreferenceManager(this);
        tokenManager = ApiClient.getInstance(this).getTokenManager();

        // 테마 적용
        prefManager.applyTheme();

        EdgeToEdge.enable(this);

        binding = ActivityMainBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());

        // 화면 보안 설정에 따라 적용
        if (prefManager.isScreenSecurityEnabled()) {
            SecurityHelper.enableScreenSecurity(this);
        }

        ViewCompat.setOnApplyWindowInsetsListener(binding.main, (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });

        securityHelper = new SecurityHelper(this);

        // 생체인증 설정이 꺼져 있으면 바로 메인 화면 표시
        if (!prefManager.isBiometricEnabled()) {
            isAuthenticated = true;
            showMainContent();
        } else {
            // 초기 상태: 메인 콘텐츠 숨김
            showAuthScreen();
        }

        // 다시 시도 버튼
        binding.btnRetry.setOnClickListener(v -> requestBiometricAuth());

        // FAB - 자산 입력 화면으로 이동
        binding.fabAdd.setOnClickListener(v -> {
            Intent intent = new Intent(this, InputActivity.class);
            startActivity(intent);
        });

        // 로그인된 사용자의 경우 주기적 동기화 시작
        if (tokenManager.isLoggedIn()) {
            SyncWorker.enqueuePeriodicSync(this);
        }
    }

    @Override
    protected void onResume() {
        super.onResume();

        // 생체인증이 비활성화되어 있으면 항상 인증된 상태
        if (!prefManager.isBiometricEnabled()) {
            if (!isAuthenticated) {
                isAuthenticated = true;
                showMainContent();
            }
            return;
        }

        // 타임아웃 체크: 5분 이상 백그라운드에 있었으면 재인증
        if (isAuthenticated && lastPausedTime > 0) {
            long elapsed = System.currentTimeMillis() - lastPausedTime;
            if (elapsed > AUTH_TIMEOUT_MS) {
                isAuthenticated = false;
            }
        }

        if (!isAuthenticated) {
            requestBiometricAuth();
        }

        // 로그인된 사용자의 경우 동기화 시도
        if (isAuthenticated && tokenManager.isLoggedIn()) {
            triggerSync();
        }
    }

    @Override
    protected void onPause() {
        super.onPause();
        // 백그라운드로 갈 때 시간 기록
        lastPausedTime = System.currentTimeMillis();
    }

    // 인증 타임아웃 (5분)
    private static final long AUTH_TIMEOUT_MS = 5 * 60 * 1000;
    private long lastPausedTime = 0;

    private boolean isDebugBuild() {
        return (getApplicationInfo().flags & android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) != 0;
    }

    private void requestBiometricAuth() {
        BiometricStatus status = securityHelper.checkBiometricAvailability();

        // Debug 빌드에서 인증 불가 시 건너뛰기
        if (isDebugBuild() && status != BiometricStatus.AVAILABLE) {
            isAuthenticated = true;
            showMainContent();
            return;
        }

        switch (status) {
            case AVAILABLE:
                // 생체 인증 또는 PIN/패턴/비밀번호로 인증
                performBiometricAuth();
                break;
            case NO_HARDWARE:
            case NOT_ENROLLED:
                // 기기 잠금이 설정되어 있으면 PIN/패턴/비밀번호로 인증 시도
                // 설정되어 있지 않으면 설정 화면으로 안내
                showError(getString(R.string.biometric_error_not_enrolled));
                binding.btnRetry.setText(R.string.go_to_settings);
                binding.btnRetry.setOnClickListener(v -> openSecuritySettings());
                break;
            case HARDWARE_UNAVAILABLE:
            case SECURITY_UPDATE_REQUIRED:
            case UNKNOWN:
                showError(getString(R.string.biometric_error_unavailable));
                break;
        }
    }

    private void openSecuritySettings() {
        Intent intent = new Intent(android.provider.Settings.ACTION_SECURITY_SETTINGS);
        startActivity(intent);
    }

    private void performBiometricAuth() {
        securityHelper.authenticate(
                this,
                getString(R.string.biometric_title),
                getString(R.string.biometric_subtitle),
                getString(R.string.biometric_negative_button),
                new SecurityHelper.AuthenticationCallback() {
                    @Override
                    public void onSuccess() {
                        isAuthenticated = true;
                        showMainContent();
                    }

                    @Override
                    public void onFailed() {
                        Toast.makeText(MainActivity.this,
                                R.string.biometric_auth_failed,
                                Toast.LENGTH_SHORT).show();
                    }

                    @Override
                    public void onError(int errorCode, String errorMessage) {
                        // 사용자가 취소한 경우 (errorCode 10, 13)
                        if (errorCode == 10 || errorCode == 13) {
                            showAuthScreen();
                        } else {
                            showError(errorMessage);
                        }
                    }
                }
        );
    }

    private void showAuthScreen() {
        binding.authContainer.setVisibility(View.VISIBLE);
        binding.mainContent.setVisibility(View.GONE);
    }

    private void showMainContent() {
        binding.authContainer.setVisibility(View.GONE);
        binding.mainContent.setVisibility(View.VISIBLE);
    }

    private void showError(String message) {
        binding.tvAuthMessage.setText(message);
        binding.tvAuthMessage.setVisibility(View.VISIBLE);
        binding.btnRetry.setVisibility(View.VISIBLE);
    }

    /**
     * 동기화 트리거
     */
    private void triggerSync() {
        AppDatabase database = AppDatabase.getInstance(this,
                DatabaseKeyManager.getKey());
        SyncRepository syncRepository = new SyncRepository(this, database);

        syncRepository.sync(new SyncRepository.SyncCallback() {
            @Override
            public void onSuccess() {
                // 동기화 성공 - UI 업데이트는 필요시
            }

            @Override
            public void onError(String message) {
                // 백그라운드 동기화 실패 - 무시 (오프라인 모드)
            }
        });
    }

    /**
     * 로그인 화면으로 이동
     */
    public void navigateToLogin() {
        Intent intent = new Intent(this, LoginActivity.class);
        startActivity(intent);
    }

    /**
     * 현재 로그인 상태 확인
     */
    public boolean isUserLoggedIn() {
        return tokenManager.isLoggedIn();
    }

    /**
     * 현재 사용자 이름 반환
     */
    public String getCurrentUserName() {
        return tokenManager.getName();
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        binding = null;
    }
}
