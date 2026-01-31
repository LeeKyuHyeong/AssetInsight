package com.example.assetinsight.data.repository;

import android.content.Context;
import android.os.Build;

import androidx.annotation.NonNull;

import com.example.assetinsight.data.local.AppDatabase;
import com.example.assetinsight.data.local.entity.UserProfile;
import com.example.assetinsight.data.remote.ApiClient;
import com.example.assetinsight.data.remote.TokenManager;
import com.example.assetinsight.data.remote.api.AuthApi;
import com.example.assetinsight.data.remote.dto.ApiResponse;
import com.example.assetinsight.data.remote.dto.AuthDto;

import java.io.IOException;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;
import timber.log.Timber;

/**
 * 인증 관련 Repository
 */
public class AuthRepository {

    private final AuthApi authApi;
    private final TokenManager tokenManager;
    private final AppDatabase database;
    private final Context context;
    private final ExecutorService executor;

    public interface AuthCallback {
        void onSuccess(AuthDto.AuthResponse response);
        void onError(String message);
    }

    public interface SimpleCallback {
        void onSuccess();
        void onError(String message);
    }

    public AuthRepository(Context context, AppDatabase database) {
        ApiClient apiClient = ApiClient.getInstance(context);
        this.authApi = apiClient.getAuthApi();
        this.tokenManager = apiClient.getTokenManager();
        this.database = database;
        this.context = context.getApplicationContext();
        this.executor = Executors.newSingleThreadExecutor();
    }

    private String getDeviceInfo() {
        return Build.MANUFACTURER + " " + Build.MODEL + " (Android " + Build.VERSION.RELEASE + ")";
    }

    /**
     * 이메일 회원가입
     */
    public void signUp(String email, String password, String name, AuthCallback callback) {
        AuthDto.SignUpRequest request = new AuthDto.SignUpRequest(email, password, name);
        authApi.signUp(request).enqueue(new Callback<ApiResponse<AuthDto.AuthResponse>>() {
            @Override
            public void onResponse(@NonNull Call<ApiResponse<AuthDto.AuthResponse>> call,
                                   @NonNull Response<ApiResponse<AuthDto.AuthResponse>> response) {
                handleAuthResponse(response, "LOCAL", callback);
            }

            @Override
            public void onFailure(@NonNull Call<ApiResponse<AuthDto.AuthResponse>> call,
                                  @NonNull Throwable t) {
                Timber.e(t, "SignUp failed");
                callback.onError("네트워크 오류: " + t.getMessage());
            }
        });
    }

    /**
     * 이메일 로그인
     */
    public void login(String email, String password, AuthCallback callback) {
        AuthDto.LoginRequest request = new AuthDto.LoginRequest(email, password, getDeviceInfo());
        authApi.login(request).enqueue(new Callback<ApiResponse<AuthDto.AuthResponse>>() {
            @Override
            public void onResponse(@NonNull Call<ApiResponse<AuthDto.AuthResponse>> call,
                                   @NonNull Response<ApiResponse<AuthDto.AuthResponse>> response) {
                handleAuthResponse(response, "LOCAL", callback);
            }

            @Override
            public void onFailure(@NonNull Call<ApiResponse<AuthDto.AuthResponse>> call,
                                  @NonNull Throwable t) {
                Timber.e(t, "Login failed");
                callback.onError("네트워크 오류: " + t.getMessage());
            }
        });
    }

    /**
     * Google OAuth 로그인
     */
    public void googleLogin(String idToken, AuthCallback callback) {
        AuthDto.OAuthLoginRequest request = new AuthDto.OAuthLoginRequest(idToken, getDeviceInfo());
        authApi.googleLogin(request).enqueue(new Callback<ApiResponse<AuthDto.AuthResponse>>() {
            @Override
            public void onResponse(@NonNull Call<ApiResponse<AuthDto.AuthResponse>> call,
                                   @NonNull Response<ApiResponse<AuthDto.AuthResponse>> response) {
                handleAuthResponse(response, "GOOGLE", callback);
            }

            @Override
            public void onFailure(@NonNull Call<ApiResponse<AuthDto.AuthResponse>> call,
                                  @NonNull Throwable t) {
                Timber.e(t, "Google login failed");
                callback.onError("Google 로그인 실패: " + t.getMessage());
            }
        });
    }

    /**
     * Kakao OAuth 로그인
     */
    public void kakaoLogin(String accessToken, AuthCallback callback) {
        AuthDto.OAuthLoginRequest request = new AuthDto.OAuthLoginRequest(accessToken, getDeviceInfo());
        authApi.kakaoLogin(request).enqueue(new Callback<ApiResponse<AuthDto.AuthResponse>>() {
            @Override
            public void onResponse(@NonNull Call<ApiResponse<AuthDto.AuthResponse>> call,
                                   @NonNull Response<ApiResponse<AuthDto.AuthResponse>> response) {
                handleAuthResponse(response, "KAKAO", callback);
            }

            @Override
            public void onFailure(@NonNull Call<ApiResponse<AuthDto.AuthResponse>> call,
                                  @NonNull Throwable t) {
                Timber.e(t, "Kakao login failed");
                callback.onError("카카오 로그인 실패: " + t.getMessage());
            }
        });
    }

    /**
     * Naver OAuth 로그인
     */
    public void naverLogin(String accessToken, AuthCallback callback) {
        AuthDto.OAuthLoginRequest request = new AuthDto.OAuthLoginRequest(accessToken, getDeviceInfo());
        authApi.naverLogin(request).enqueue(new Callback<ApiResponse<AuthDto.AuthResponse>>() {
            @Override
            public void onResponse(@NonNull Call<ApiResponse<AuthDto.AuthResponse>> call,
                                   @NonNull Response<ApiResponse<AuthDto.AuthResponse>> response) {
                handleAuthResponse(response, "NAVER", callback);
            }

            @Override
            public void onFailure(@NonNull Call<ApiResponse<AuthDto.AuthResponse>> call,
                                  @NonNull Throwable t) {
                Timber.e(t, "Naver login failed");
                callback.onError("네이버 로그인 실패: " + t.getMessage());
            }
        });
    }

    /**
     * 토큰 갱신
     */
    public void refreshToken(AuthCallback callback) {
        String refreshToken = tokenManager.getRefreshToken();
        if (refreshToken == null) {
            callback.onError("로그인이 필요합니다");
            return;
        }

        AuthDto.RefreshTokenRequest request = new AuthDto.RefreshTokenRequest(refreshToken);
        authApi.refreshToken(request).enqueue(new Callback<ApiResponse<AuthDto.AuthResponse>>() {
            @Override
            public void onResponse(@NonNull Call<ApiResponse<AuthDto.AuthResponse>> call,
                                   @NonNull Response<ApiResponse<AuthDto.AuthResponse>> response) {
                if (response.isSuccessful() && response.body() != null && response.body().isSuccess()) {
                    AuthDto.AuthResponse data = response.body().getData();
                    tokenManager.updateAccessToken(data.accessToken, data.expiresIn);
                    callback.onSuccess(data);
                } else {
                    // 토큰 갱신 실패 시 로그아웃
                    tokenManager.clearTokens();
                    callback.onError("세션이 만료되었습니다. 다시 로그인해주세요.");
                }
            }

            @Override
            public void onFailure(@NonNull Call<ApiResponse<AuthDto.AuthResponse>> call,
                                  @NonNull Throwable t) {
                callback.onError("네트워크 오류: " + t.getMessage());
            }
        });
    }

    /**
     * 토큰 갱신 (동기)
     */
    public boolean refreshTokenSync() {
        String refreshToken = tokenManager.getRefreshToken();
        if (refreshToken == null) {
            return false;
        }

        try {
            AuthDto.RefreshTokenRequest request = new AuthDto.RefreshTokenRequest(refreshToken);
            Response<ApiResponse<AuthDto.AuthResponse>> response = authApi.refreshToken(request).execute();

            if (response.isSuccessful() && response.body() != null && response.body().isSuccess()) {
                AuthDto.AuthResponse data = response.body().getData();
                tokenManager.updateAccessToken(data.accessToken, data.expiresIn);
                return true;
            }
        } catch (IOException e) {
            Timber.e(e, "Token refresh failed");
        }
        return false;
    }

    /**
     * 로그아웃
     */
    public void logout(SimpleCallback callback) {
        // 서버에 로그아웃 알림 (실패해도 로컬은 정리)
        authApi.logout().enqueue(new Callback<ApiResponse<Void>>() {
            @Override
            public void onResponse(@NonNull Call<ApiResponse<Void>> call,
                                   @NonNull Response<ApiResponse<Void>> response) {
                clearLocalSession();
                callback.onSuccess();
            }

            @Override
            public void onFailure(@NonNull Call<ApiResponse<Void>> call,
                                  @NonNull Throwable t) {
                clearLocalSession();
                callback.onSuccess();
            }
        });
    }

    /**
     * 로컬 세션 정리
     */
    private void clearLocalSession() {
        tokenManager.clearTokens();
        executor.execute(() -> {
            database.clearLocalData();
        });
    }

    /**
     * 현재 로그인 상태 확인
     */
    public boolean isLoggedIn() {
        return tokenManager.isLoggedIn();
    }

    /**
     * 토큰 만료 여부 확인
     */
    public boolean isTokenExpired() {
        return tokenManager.isTokenExpired();
    }

    /**
     * 현재 사용자 ID
     */
    public String getCurrentUserId() {
        return tokenManager.getUserId();
    }

    /**
     * 현재 사용자 이메일
     */
    public String getCurrentUserEmail() {
        return tokenManager.getEmail();
    }

    /**
     * 현재 사용자 이름
     */
    public String getCurrentUserName() {
        return tokenManager.getName();
    }

    /**
     * 저장된 프로필 목록 조회
     */
    public void getProfiles(DataCallback<List<UserProfile>> callback) {
        executor.execute(() -> {
            try {
                List<UserProfile> profiles = database.userProfileDao().getAllProfiles();
                callback.onSuccess(profiles);
            } catch (Exception e) {
                callback.onError(e.getMessage());
            }
        });
    }

    /**
     * 현재 활성 프로필 조회
     */
    public void getActiveProfile(DataCallback<UserProfile> callback) {
        executor.execute(() -> {
            try {
                UserProfile profile = database.userProfileDao().getActiveProfile();
                callback.onSuccess(profile);
            } catch (Exception e) {
                callback.onError(e.getMessage());
            }
        });
    }

    /**
     * 프로필 전환
     */
    public void switchProfile(String userId, SimpleCallback callback) {
        executor.execute(() -> {
            try {
                // 기존 데이터 정리
                database.clearLocalData();

                // 프로필 활성화
                database.userProfileDao().deactivateAll();
                database.userProfileDao().activateProfile(userId);

                // 토큰 정보 로드 (프로필에 저장된 토큰이 있다면)
                // 주의: 실제 구현에서는 프로필별 토큰을 저장하거나 재로그인 필요

                callback.onSuccess();
            } catch (Exception e) {
                callback.onError(e.getMessage());
            }
        });
    }

    /**
     * 응답 처리 공통 메서드
     */
    private void handleAuthResponse(Response<ApiResponse<AuthDto.AuthResponse>> response,
                                    String provider, AuthCallback callback) {
        if (response.isSuccessful() && response.body() != null) {
            ApiResponse<AuthDto.AuthResponse> body = response.body();
            if (body.isSuccess() && body.getData() != null) {
                AuthDto.AuthResponse data = body.getData();

                // 토큰 저장
                tokenManager.saveTokens(
                        data.userId, data.email, data.name,
                        data.accessToken, data.refreshToken, data.expiresIn
                );

                // 프로필 저장
                executor.execute(() -> {
                    database.userProfileDao().deactivateAll();
                    UserProfile profile = new UserProfile(
                            data.userId, data.email, data.name, provider, true
                    );
                    database.userProfileDao().insert(profile);
                });

                callback.onSuccess(data);
            } else {
                callback.onError(body.getMessage());
            }
        } else {
            String errorMessage = "서버 오류";
            try {
                if (response.errorBody() != null) {
                    errorMessage = response.errorBody().string();
                }
            } catch (IOException e) {
                Timber.e(e, "Error reading error body");
            }
            callback.onError(errorMessage);
        }
    }

    public interface DataCallback<T> {
        void onSuccess(T data);
        void onError(String message);
    }
}
