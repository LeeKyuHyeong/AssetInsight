package com.example.assetinsight.ui.auth;

import android.content.Intent;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.View;
import android.widget.Toast;

import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.credentials.CredentialManager;
import androidx.credentials.CredentialManagerCallback;
import androidx.credentials.GetCredentialRequest;
import androidx.credentials.GetCredentialResponse;
import androidx.credentials.exceptions.GetCredentialException;

import com.example.assetinsight.BuildConfig;
import com.example.assetinsight.MainActivity;
import com.example.assetinsight.R;
import com.example.assetinsight.data.local.AppDatabase;
import com.example.assetinsight.data.repository.AuthRepository;
import com.example.assetinsight.data.remote.dto.AuthDto;
import com.example.assetinsight.databinding.ActivityLoginBinding;
import com.example.assetinsight.service.SyncWorker;
import com.example.assetinsight.util.DatabaseKeyManager;
import com.google.android.libraries.identity.googleid.GetGoogleIdOption;
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential;
import com.kakao.sdk.auth.model.OAuthToken;
import com.kakao.sdk.user.UserApiClient;
import com.navercorp.nid.NaverIdLoginSDK;
import com.navercorp.nid.oauth.NidOAuthLogin;
import com.navercorp.nid.oauth.OAuthLoginCallback;

import java.util.concurrent.Executors;

import kotlin.Unit;
import kotlin.jvm.functions.Function2;
import timber.log.Timber;

public class LoginActivity extends AppCompatActivity {

    private ActivityLoginBinding binding;
    private AuthRepository authRepository;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);

        binding = ActivityLoginBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());

        ViewCompat.setOnApplyWindowInsetsListener(binding.main, (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });

        // Initialize SDK
        initializeSdk();

        // Initialize repository
        AppDatabase database = AppDatabase.getInstance(this,
                DatabaseKeyManager.getKey());
        authRepository = new AuthRepository(this, database);

        setupClickListeners();
    }

    private void initializeSdk() {
        // Initialize Kakao SDK
        if (!TextUtils.isEmpty(BuildConfig.KAKAO_APP_KEY)) {
            com.kakao.sdk.common.KakaoSdk.init(this, BuildConfig.KAKAO_APP_KEY);
        }

        // Initialize Naver SDK
        if (!TextUtils.isEmpty(BuildConfig.NAVER_CLIENT_ID)) {
            NaverIdLoginSDK.INSTANCE.initialize(
                    this,
                    BuildConfig.NAVER_CLIENT_ID,
                    BuildConfig.NAVER_CLIENT_SECRET,
                    getString(R.string.app_name)
            );
        }
    }

    private void setupClickListeners() {
        // Email login
        binding.btnLogin.setOnClickListener(v -> performEmailLogin());

        // Sign up link
        binding.tvSignUp.setOnClickListener(v -> {
            startActivity(new Intent(this, SignupActivity.class));
        });

        // Google login
        binding.btnGoogleLogin.setOnClickListener(v -> performGoogleLogin());

        // Kakao login
        binding.btnKakaoLogin.setOnClickListener(v -> performKakaoLogin());

        // Naver login
        binding.btnNaverLogin.setOnClickListener(v -> performNaverLogin());

        // Skip login (for offline mode)
        binding.tvSkipLogin.setOnClickListener(v -> {
            navigateToMain();
        });
    }

    private void performEmailLogin() {
        String email = binding.etEmail.getText().toString().trim();
        String password = binding.etPassword.getText().toString();

        if (TextUtils.isEmpty(email)) {
            binding.tilEmail.setError("이메일을 입력하세요");
            return;
        }
        if (TextUtils.isEmpty(password)) {
            binding.tilPassword.setError("비밀번호를 입력하세요");
            return;
        }

        binding.tilEmail.setError(null);
        binding.tilPassword.setError(null);
        showLoading(true);

        authRepository.login(email, password, new AuthRepository.AuthCallback() {
            @Override
            public void onSuccess(AuthDto.AuthResponse response) {
                runOnUiThread(() -> {
                    showLoading(false);
                    onLoginSuccess();
                });
            }

            @Override
            public void onError(String message) {
                runOnUiThread(() -> {
                    showLoading(false);
                    Toast.makeText(LoginActivity.this, message, Toast.LENGTH_SHORT).show();
                });
            }
        });
    }

    private void performGoogleLogin() {
        if (TextUtils.isEmpty(BuildConfig.GOOGLE_CLIENT_ID)) {
            Toast.makeText(this, "Google 로그인이 설정되지 않았습니다", Toast.LENGTH_SHORT).show();
            return;
        }

        showLoading(true);

        GetGoogleIdOption googleIdOption = new GetGoogleIdOption.Builder()
                .setFilterByAuthorizedAccounts(false)
                .setServerClientId(BuildConfig.GOOGLE_CLIENT_ID)
                .build();

        GetCredentialRequest request = new GetCredentialRequest.Builder()
                .addCredentialOption(googleIdOption)
                .build();

        CredentialManager credentialManager = CredentialManager.create(this);
        credentialManager.getCredentialAsync(
                this,
                request,
                null,
                Executors.newSingleThreadExecutor(),
                new CredentialManagerCallback<GetCredentialResponse, GetCredentialException>() {
                    @Override
                    public void onResult(GetCredentialResponse result) {
                        handleGoogleSignInResult(result);
                    }

                    @Override
                    public void onError(GetCredentialException e) {
                        runOnUiThread(() -> {
                            showLoading(false);
                            Timber.e(e, "Google sign in failed");
                            Toast.makeText(LoginActivity.this,
                                    "Google 로그인 실패: " + e.getMessage(),
                                    Toast.LENGTH_SHORT).show();
                        });
                    }
                }
        );
    }

    private void handleGoogleSignInResult(GetCredentialResponse result) {
        if (result.getCredential() instanceof GoogleIdTokenCredential) {
            GoogleIdTokenCredential credential = (GoogleIdTokenCredential) result.getCredential();
            String idToken = credential.getIdToken();

            authRepository.googleLogin(idToken, new AuthRepository.AuthCallback() {
                @Override
                public void onSuccess(AuthDto.AuthResponse response) {
                    runOnUiThread(() -> {
                        showLoading(false);
                        onLoginSuccess();
                    });
                }

                @Override
                public void onError(String message) {
                    runOnUiThread(() -> {
                        showLoading(false);
                        Toast.makeText(LoginActivity.this, message, Toast.LENGTH_SHORT).show();
                    });
                }
            });
        } else {
            runOnUiThread(() -> {
                showLoading(false);
                Toast.makeText(this, "Google 로그인 실패", Toast.LENGTH_SHORT).show();
            });
        }
    }

    private void performKakaoLogin() {
        if (TextUtils.isEmpty(BuildConfig.KAKAO_APP_KEY)) {
            Toast.makeText(this, "카카오 로그인이 설정되지 않았습니다", Toast.LENGTH_SHORT).show();
            return;
        }

        showLoading(true);

        Function2<OAuthToken, Throwable, Unit> callback = (token, error) -> {
            if (error != null) {
                runOnUiThread(() -> {
                    showLoading(false);
                    Timber.e(error, "Kakao login failed");
                    Toast.makeText(this, "카카오 로그인 실패: " + error.getMessage(),
                            Toast.LENGTH_SHORT).show();
                });
            } else if (token != null) {
                authRepository.kakaoLogin(token.getAccessToken(), new AuthRepository.AuthCallback() {
                    @Override
                    public void onSuccess(AuthDto.AuthResponse response) {
                        runOnUiThread(() -> {
                            showLoading(false);
                            onLoginSuccess();
                        });
                    }

                    @Override
                    public void onError(String message) {
                        runOnUiThread(() -> {
                            showLoading(false);
                            Toast.makeText(LoginActivity.this, message, Toast.LENGTH_SHORT).show();
                        });
                    }
                });
            }
            return null;
        };

        if (UserApiClient.getInstance().isKakaoTalkLoginAvailable(this)) {
            UserApiClient.getInstance().loginWithKakaoTalk(this, callback);
        } else {
            UserApiClient.getInstance().loginWithKakaoAccount(this, callback);
        }
    }

    private void performNaverLogin() {
        if (TextUtils.isEmpty(BuildConfig.NAVER_CLIENT_ID)) {
            Toast.makeText(this, "네이버 로그인이 설정되지 않았습니다", Toast.LENGTH_SHORT).show();
            return;
        }

        showLoading(true);

        OAuthLoginCallback oauthLoginCallback = new OAuthLoginCallback() {
            @Override
            public void onSuccess() {
                String accessToken = NaverIdLoginSDK.INSTANCE.getAccessToken();
                if (accessToken != null) {
                    authRepository.naverLogin(accessToken, new AuthRepository.AuthCallback() {
                        @Override
                        public void onSuccess(AuthDto.AuthResponse response) {
                            runOnUiThread(() -> {
                                showLoading(false);
                                onLoginSuccess();
                            });
                        }

                        @Override
                        public void onError(String message) {
                            runOnUiThread(() -> {
                                showLoading(false);
                                Toast.makeText(LoginActivity.this, message, Toast.LENGTH_SHORT).show();
                            });
                        }
                    });
                }
            }

            @Override
            public void onFailure(int httpStatus, String message) {
                runOnUiThread(() -> {
                    showLoading(false);
                    Toast.makeText(LoginActivity.this,
                            "네이버 로그인 실패: " + message, Toast.LENGTH_SHORT).show();
                });
            }

            @Override
            public void onError(int errorCode, String message) {
                onFailure(errorCode, message);
            }
        };

        NaverIdLoginSDK.INSTANCE.authenticate(this, oauthLoginCallback);
    }

    private void onLoginSuccess() {
        Toast.makeText(this, "로그인 성공", Toast.LENGTH_SHORT).show();

        // 백그라운드 동기화 시작
        SyncWorker.enqueueOneTime(this);

        navigateToMain();
    }

    private void navigateToMain() {
        Intent intent = new Intent(this, MainActivity.class);
        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
        startActivity(intent);
        finish();
    }

    private void showLoading(boolean show) {
        binding.progressBar.setVisibility(show ? View.VISIBLE : View.GONE);
        binding.btnLogin.setEnabled(!show);
        binding.btnGoogleLogin.setEnabled(!show);
        binding.btnKakaoLogin.setEnabled(!show);
        binding.btnNaverLogin.setEnabled(!show);
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        binding = null;
    }
}
